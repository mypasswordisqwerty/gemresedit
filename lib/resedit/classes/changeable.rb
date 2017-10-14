require 'resedit/classes/colorizer'
require 'resedit/classes/hexwriter'
require 'logger'

module Resedit

    class Changeable
        HOW_CHANGED = 0
        HOW_ORIGINAL = 1
        COL_CHANGED = Colorizer::YELLOW
        COL_ORIGINAL = Colorizer::PURPLE
        LOG = Logger.new(STDOUT)

        class Sector

            FLAG_CHANGED = 1
            FLAG_NEIGH_CHANGE = 2
            FLAG_NU = 4

            attr_accessor :buf, :o, :c, :flags

            def initialize(buf, flags=0)
                @o = nil
                @c = nil
                @buf = buf ? buf : ''
                @sz = @buf.length
                @flags = flags
            end

            def fch?; @flags & FLAG_CHANGED !=0 end
            def fnu?; @flags & FLAG_NU !=0 end
            def fnch?; @flags & FLAG_NEIGH_CHANGE !=0 end

            def _next(how, change=false)
                return @c if change && !@c.fnu?
                return (how == HOW_CHANGED ? @c : @o)
            end

            def data(ofs, size, how)
                return _next(how).data(ofs - @sz, size, how) if ofs > @sz
                return @buf[ofs, -1] + _next(how).data(0, size - @sz + ofs, how) if @sz < ofs+size
                return @buf[ofs, size]
            end

            def all(how)
                n = _next(how)
                return @buf + (n ? n.all(how) : '')
            end

            def size(how)
                n = _next(how)
                return @sz + (n ? n.size(how) : 0)
            end

            def split(ofs, data, nu=false)
                tail = Sector.new(@buf[ofs + (nu ? 0 : data.length) .. -1])
                tail.o = @o
                tail.c = @c
                cs = Sector.new(data, FLAG_CHANGED | (nu ? FLAG_NU : 0))
                cs.o = cs.c = tail
                if !nu
                    os = Sector.new(@buf[ofs, data.length], FLAG_NEIGH_CHANGE)
                    os.o = os.c = tail
                else
                    os = tail
                end
                @buf = @buf[0, ofs]
                @sz = @buf.length
                @o = os
                @c = cs
            end

            def insert(ofs, data, how)
                return @sz + _next(how).insert(ofs - @sz, data, how) if ofs > @sz
                LOG.debug("inserting #{data} @#{ofs} of #{@buf} #{@sz}")
                if fnu?
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
                if fch?
                    @buf = @buf[0,ofs] + data[0, size] + @buf[ofs+size..-1]
                    return ofs
                end
                split(ofs, data, false)
                return ofs
            end

            def undo(ofs, how)
                LOG.debug("undo #{ofs} #{@buf}")
                return _next(how).undo(ofs - @sz, how) if ofs > @sz
                raise "Change not found #{buf} #{ofs}" if ofs != @sz || !@c.fch?
                @c = @o
                @o.flags = 0 if @o
            end

            def revert
                @c = @o
                @o.flags = 0 if @o
                @o.revert if @o
            end

            def changed?(ofs, size, how)
                return _next(how).changed?(ofs - @sz, size, how) if ofs > @sz
                return true if fch? || fnch?
                return _next(how).changed?(0, size - @sz + ofs, how) if @sz < ofs+size
                return false
            end

            def hex(writer, ofs, size, col, how)
                n = _next(how)
                if ofs > @sz
                    return size if !n
                    return n.hex(writer, ofs - @sz, size, col, how)
                end
                sz = @sz < ofs+size ? @sz-ofs : size
                writer.addBytes(@buf[ofs, sz], fch? || fnch? ? col : nil)
                LOG.debug("printed #{@buf[ofs, sz]} #{sz} #{size}")
                return 0 if sz==size
                return n.hex(writer, 0, size-sz, col, how) if n
                return size-sz
            end

            def getChanges(how, ofs=0)
                ch = {}
                n = _next(how)
                if @flags != 0
                    ch[ofs] = @buf
                    LOG.debug("add change #{ofs} = #{@buf}, #{ch}")
                end
                ch = ch.merge(n.getChanges(how, ofs+@sz)) if n
                return ch
            end

            def normalize(neig)
                return if !@c
                while @flags == 0 && @o.flags == 0 && @c==@o
                    @c = @o.c
                    @buf += @o.buf
                    @sz = @buf.length
                    @o = @o.o
                    return if !@o
                end
                while @o.flags==0 && @o.buf == '' && @o.c && @o.c.flags == @flags && neig.o==@o
                    neig.o=@o.o.o
                    neig.c=@o.o.c
                    neig.buf += @o.o.buf
                    @buf += @o.c.buf
                    @sz = @buf.length
                    @c = @o.c.c
                    @o = @o.c.o
                end
                @c.normalize(@o)
            end

            def dump(neig)
                n = fch? ? (fnu? ? "N" : "C") : "O"
                printf("#{n}(#{@buf},#{@flags})")
                if neig != self
                    if neig.o == @o
                        printf("\t\tO(#{neig.buf},#{neig.flags})")
                        neig = neig.o
                    else
                        printf("\t\t|")
                    end
                else
                    neig = @o
                end
                puts
                @c.dump(neig) if @c
            end
        end

        # Changeable

        def initialize(fileOrBytes, fileSize=nil)
            LOG.level = Logger::INFO
            @col = Colorizer.instance()
            @mode = HOW_CHANGED
            @oSec = nil
            @cSec = nil
            @root = nil
            addData(fileOrBytes, fileSize)
        end

        def addData(fileOrBytes, size=nil)
            if fileOrBytes.is_a?(IO)
                data = fileOrBytes.read(size)
            else
                data = fileOrBytes
            end
            data = @oSec.buf + data if @oSec
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
                nu = Sector.new(data, Sector::FLAG_CHANGED | Sector::FLAG_NU)
                nu.o = nu.c = @cSec
                @cSec=nu
                mode(@mode)
            else
                @root.insert(offset, data, @mode)
            end
            @cSec.normalize(@oSec)
        end

        def undo(offset)
            if offset==0 and @cSec.fnu?
                @cSec = @cSec.o
                mode(@mode)
            else
                @root.undo(offset, @mode)
            end
            @cSec.normalize(@oSec)
        end

        def change(ofs, bytes)
            @root.change(ofs, bytes, @mode)
            @cSec.normalize(@oSec)
        end

        def changed?(ofs, size=1); return @root.changed?(ofs, size, @mode) end

        def debug(); LOG.level = Logger::DEBUG end

        def dbgdump
            LOG.debug("---#{@cSec.all(HOW_CHANGED)}---#{@oSec.all(HOW_ORIGINAL)}---\n")
            @cSec.dump(@oSec)
        end

        def getData(ofs, size); return root.data(ofs, size, @mode) end

        def bytes; return @root.all(@mode) end

        def getChanges; @root.getChanges(@mode); end

        def revert(what)
            if what=='all'
                @oSec.revert()
                @cSec = @oSec
                mode(@mode)
                @cSec.normalize(@oSec)
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
            return @root.hex(writer, ofs, size, col, @mode)
        end


        def saveData(file)
            mode(HOW_CHANGED)
            file.write(bytes())
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
