require 'resedit/classes/colorizer'
require 'resedit/classes/hexwriter'

module Resedit

    class Changeable
        HOW_CHANGED = 0
        HOW_ORIGINAL = 1
        COL_CHANGED = Colorizer::YELLOW
        COL_ORIGINAL = Colorizer::PURPLE

        class Sector

            attr_accessor :buf, :o, :c, :changed, :nu

            def initialize(buf, changed = false, nu = false)
                @o = nil
                @c = nil
                @buf = buf
                @sz = buf.length
                @changed = changed
                @nu = nu
            end

            def _next(how, change=false)
                return @c if change && !@c.nu
                return (how == HOW_CHANGED ? @c : @o)
            end

            def data(ofs, size, how)
                return _next(how).data(ofs - @sz, size, how) if ofs > @sz
                return @buf[ofs, -1] + _next(how).data(0, size - @sz + ofs, how) if @sz < ofs+size
                return @buf[ofs, size]
            end

            def split(ofs, data, nu=false)
                tail = Sector.new(@buf[ofs + (nu ? 0 : data.length) .. -1])
                tail.o = @o
                tail.c = @c
                cs = Sector.new(data, true, nu)
                cs.o = cs.c = tail
                if !nu
                    os = Sector.new(@buf[ofs, data.length])
                    os.o = os.c = tail
                else
                    os = tail
                end
                @o = os
                @c = cs
            end

            def insert(ofs, data, how)
                return @sz + _next(how).insert(ofs - @sz, data, how) if ofs > @sz
                if @nu
                    @buf = @buf[0, ofs] + data + @buf[ofs..-1]
                    @sz += data.length
                    return ofs
                end
                split(ofs, data, true)
                return ofs
            end

            def change(ofs, data, how)
                return @sz + _next(how, true).change(ofs - @sz, data, how) if ofs > @sz
                nxt = data.length - @sz + ofs
                size = nxt>0 ? data.length-nxt : data.length
                _next(how, true).change(0, data[size..-1], how) if nxt > 0
                if @changed
                    @buf = @buf[0,ofs] + data[0, size] + @buf[ofs+size..-1]
                    return ofs
                end
                split(ofs, data, true)
                return ofs
            end

            def undo(ofs, how)
                return _next(how).removeChange(ofs - @sz) if ofs > @sz
                raise "Change not found" if ofs!=sz || !@c.changed
                @c = @o
            end

            def revert
                @c = @o
                @o.revert if @o
            end

            def changed?(ofs, size, how)
                return _next(how).changed?(ofs - @sz, size, how) if ofs > @sz
                return true if @changed || @c!=@o
                return _next(how).changed?(0, size - @sz + ofs, how) if @sz < ofs+size
                return false
            end

            def hex(writer, ofs, size, col, how)
                n = _next(how)
                if ofs > @sz
                    return size if not n
                    n.hex(writer, ofs - @sz, size, col, how)
                end
                sz = @sz < ofs+size ? size : size
                writer.addBytes(@buf[ofs, sz], @changed ? col : nil)
                return 0 if sz==size
                return n.hex(writer, 0, size-sz, col, how)
            end
        end

        # Changeable

        def initialize(fileOrBytes, fileSize=nil)
            @col = Colorizer.instance()
            @mode = HOW_CHANGED
            addData(fileOrBytes, fileSize)
        end

        def addData(fileOrBytes, size=nil)
            if fileOrBytes.is_a?(IO)
                data = fileOrBytes.read(size)
            else
                data = fileOrBytes
            end
            data = @oSec.buf + data if buf
            @oSec = Sector.new(data)
            @cSec = @oSec
            @root = @cSec
        end


        def mode(how)
            @root = how == HOW_CHANGED ? @cSec : @oSec
            @mode = how
        end

        def insert(offset, data)
            return if !data || !data.length
            if offset==0
                nu = Sector.new(data, true, true)
                nu.o = nu.c = @cSec
                @cSec=nu
                mode(@mode)
            else
                root.insert(offset, data, @mode)
            end
        end

        def undo(offset)
            if offset==0 and @cSec.nu
                @cSec = @cSec.o
                mode(@mode)
            else
                root.undo(offset, @mode)
            end
        end

        def change(ofs, bytes)
            root.change(ofs, bytes, @mode)
        end

        def changed?(ofs, size=1)
            return root.changed?(ofs, size, @mode)
        end

        def revert(what)
            if what=='all'
                while @cSec.nu
                    @cSec = @cSec.@o
                end
                @oSec.revert
                @cSec = @oSec
                mode(@mode)
                return true
            end
            undo(what)
            return true
        end

        def curcol; @mode == HOW_ORIGINAL ? COL_ORIGINAL : COL_CHANGED end

        def colVal(ofs, size)
            fmt = "%#{size*2}.#{size*2}X"
            u = size == 2 ? "v" : V
            return colStr( sprintf(fmt, getData(ofs, size).unpack(u)[0]) , changed?(ofs,size))
        end

        def colStr(str, cond=true)
            str = sprintf("%04X", str) if !str.is_a?(String)
            return str if !cond
            return @col.color(curcol(), str)
        end

        def getData(ofs, size)
            return root.data(ofs, size, @mode)
        end


        def parseHow(how)
            return HOW_CHANGED if !how || how == HOW_CHANGED
            return HOW_ORIGINAL if how == HOW_ORIGINAL
            return HOW_ORIGINAL if how[0] == 'o' || how[0] == 'O'
            return HOW_CHANGED
        end

        def print(what, how)
            mode(parseHow(how))
            if what=="changes"
                #TODO: print all changes
                return true
            end
            return false
        end


        def hex(writer, ofs, size, how)
            mode(parseHow(how))
            col = curcol()
            return root.hex(writer, ofs, size, col, how)
        end

        def saveData(file)
            file.write(@changed)
        end

        def saveChanges(file)
            raise "Not implemented"
            mode(HOW_CHANGED)
            file.write([@origSize, @changes.length].pack('VV'))
            @changes.each{|c,bts|
                file.write([c, bts.length].pack('VV'))
                file.write(bts)
            }
        end

        def loadChanges(file)
            raise "Not implemented"
            mode(HOW_CHANGED)
            @origSize, clen=file.read(12).unpack('VV')
            @add = @bytes[@origSize..-1] if @bytes.length > @origSize
            @bytes = @bytes[0, @origSize]
            for _ in 0..clen-1
                ofs, bts = file.read(8).unpack('VV')
                @changes[ofs] = file.read(bts)
            end
            @c2 = @changes.keys.reverse
            mode(HOW_ORIGINAL)
        end

    end

end
