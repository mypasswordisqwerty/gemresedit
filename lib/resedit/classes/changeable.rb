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

        class Change

            attr_reader :nbuf, :obuf
            attr_accessor :buf, :sz, :n

            def initialize(obuf=nil, nbuf=nil)
                @n = nil
                @mode = HOW_CHANGED
                _updbufs(obuf, nbuf)
            end

            def _updbufs(obuf=nil, nbuf=nil)
                @obuf = obuf ? obuf : ''
                @nbuf = nbuf
                mode()
            end

            def mode(mode=nil)
                @mode = mode if mode
                @buf = (@mode == HOW_CHANGED && @nbuf) ? @nbuf : @obuf
                @sz = @buf.length
                @n.mode(mode) if @n && mode
            end

            def data(ofs, size)
                return @n.data(ofs - @sz, size) if ofs > @sz
                return @buf[ofs, -1] + @n.data(0, size - @sz + ofs) if @sz < ofs+size
                return @buf[ofs, size]
            end

            def all; return @buf + (@n ? @n.all() : '') end
            def size; return @sz + (@n ? @n.size() : 0) end

            def split(ofs, data, nu=false)
                if ofs+(nu ? 0 : data.length) == @sz
                    tail = @n
                else
                    ntail = @nbuf ? @nbuf[ofs + (nu ? 0 : data.length) .. -1] : nil
                    tail = Change.new(@obuf[ofs + (nu ? 0 : data.length) .. -1], ntail)
                    tail.n = @n
                end
                if ofs != 0
                    body = Change.new(nu ? nil : @obuf[ofs, data.length], data)
                    body.n = tail
                    _updbufs(@buf[0, ofs], @nbuf ? @nbuf[0, ofs] : nil)
                    @n = body
                else
                    _updbufs(nu ? nil : @obuf[0, data.length], data)
                    @n = tail
                end
                mode(@mode)
            end

            def insert(ofs, data)
                return @sz + @n.insert(ofs - @sz, data) if ofs > @sz
                LOG.debug("inserting #{data} @#{ofs} of #{@buf} #{@sz}")
                if @nbuf
                    @nbuf = @nbuf[0, ofs] + data + @nbuf[ofs..-1]
                    mode()
                    return ofs
                end
                split(ofs, data, true)
                mode()
                return ofs
            end

            def change(ofs, data)
                return @sz + @n.change(ofs - @sz, data) if ofs > @sz
                nxt = data.length - @sz + ofs
                size = nxt>0 ? data.length-nxt : data.length
                @n.change(0, data[size..-1]) if nxt > 0
                if @nbuf
                    @nbuf = @nbuf[0,ofs] + data[0, size] + @nbuf[ofs+size..-1]
                    mode()
                    return ofs
                end
                split(ofs, data[0, size])
                mode()
                return ofs
            end

            def undo(ofs)
                LOG.debug("undo #{ofs} #{@buf}")
                return @n.undo(ofs - @sz) if ofs >= @sz
                raise "Change not found @#{buf}:#{ofs}" if ofs != 0 || !@nbuf
                @nbuf = nil
                mode()
            end

            def revert
                @nbuf = nil
                mode()
                @n.revert if @n
            end

            def changed?(ofs, size)
                return @n.changed?(ofs - @sz, size) if ofs > @sz
                return true if @nbuf
                return @n.changed?(0, size - @sz + ofs) if @sz < ofs+size
                return false
            end

            def hex(writer, ofs, size, col)
                if ofs > @sz
                    return size if !n
                    return n.hex(writer, ofs - @sz, size, col)
                end
                sz = @sz < ofs+size ? @sz-ofs : size
                writer.addBytes(@buf[ofs, sz], @nbuf ? col : nil)
                return 0 if sz==size
                return n.hex(writer, 0, size-sz, col) if n
                return size-sz
            end

            def getChanges(ofs=0)
                ch = {}
                if @nbuf
                    ch[ofs] = [@obuf, @nbuf]
                end
                ch = ch.merge(@n.getChanges(ofs+@sz)) if @n
                return ch
            end

            def normalize()
                while @n && !@nbuf && @obuf.length==0
                    @obuf = @n.obuf
                    @nbuf = @n.nbuf
                    @n = @n.n
                end
                @n=@n.n while @n && !@n.nbuf && @n.obuf.length==0
                while @n &&
                        ((@obuf.length>0 && @n.obuf.length>0) || (@obuf.length == 0 && @n.obuf.length==0)) &&
                        ((@nbuf && @n.nbuf) || (!@nbuf && !@n.nbuf))
                    @obuf += @n.obuf
                    @nbuf = @nbuf ? @nbuf+@n.nbuf : nil
                    @n=@n.n
                end
                mode()
                @n.normalize() if @n
            end

            def dump()
                printf("#{@sz}:O(#{@obuf})\t\t%s\n", @nbuf ? "N(#{@nbuf if @nbuf})" : "")
                @n.dump() if @n
            end
        end

        # Changeable

        def initialize(fileOrBytes, fileSize=nil)
            LOG.level = Logger::INFO
            @col = Colorizer.instance()
            @mode = HOW_CHANGED
            @root = nil
            addData(fileOrBytes, fileSize)
        end

        def addData(fileOrBytes, size=nil)
            if fileOrBytes.is_a?(IO)
                data = fileOrBytes.read(size)
            else
                data = fileOrBytes
            end
            data = @root.buf + data if @root
            @root = Change.new(data)
        end


        def mode(how)
            @root.mode(how)
            @mode = how
        end

        def insert(offset, data)
            return if !data || !data.length
            @root.insert(offset, data)
            @root.normalize()
        end

        def undo(offset)
            @root.undo(offset)
            @root.normalize()
        end

        def change(ofs, bytes)
            @root.change(ofs, bytes)
            @root.normalize()
        end

        def changed?(ofs, size=1); return @root.changed?(ofs, size) end

        def debug(); LOG.level = Logger::DEBUG end

        def dbgdump
            LOG.debug("---#{@root.all()}---\n")
            @root.dump()
        end

        def getData(ofs, size); return @root.data(ofs, size) end

        def bytes; return @root.all() end

        def getChanges; @root.getChanges(); end

        def revert(what)
            if what=='all'
                @root.revert()
                @root.normalize()
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


        def hex(writer, ofs, size, how)
            mode(parseHow(how))
            col = curcol()
            return @root.hex(writer, ofs, size, col)
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
