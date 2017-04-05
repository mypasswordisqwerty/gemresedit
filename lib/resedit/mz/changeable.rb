require 'resedit/app/colorizer'
require 'resedit/mz/hexwriter'

module Resedit

    class Changeable
        HOW_CHANGED = 0
        HOW_ORIGINAL = 1
        COL_CHANGED = Colorizer::YELLOW
        COL_ORIGINAL = Colorizer::BLUE

        attr_reader :mz, :bytes, :add, :changes, :realSize

        def initialize(mz, file, size)
            @mz = mz
            @bytes = file.read(size)
            @realSize = @bytes.size
            @add = nil
            @changes = {}
            @col = App::get().col
            @mode = HOW_ORIGINAL
        end

        def readMore(file, size)
            @bytes += file.read(size)
            @realSize = @bytes.size
        end


        def mode(how)
            return if @mode == how
            if how == HOW_CHANGED
                @bytes += @add if @add
            else
                @add = @bytes[@realSize,-1] if @bytes.length > @realSize
                @bytes = @bytes[0, @realSize]
            end
            @changes.each{|c,bts|
                @changes[c] = @bytes[c, bts.length]
                bts.each_byte{|b|
                    @bytes[c] = b.chr
                    c += 1
                }
            }
            @mode = how
        end

        def append(bytes)
            @add = @add ? @add + bytes : bytes
            @size = @bytes.length + @add.length
        end

        def removeAppend()
            @add = nil
            @bytes = @bytes[0,@realSize]
        end


        def changed?(ofs, size=2)
            return true if ofs+size > @realSize
            lower = @changes.keys.reverse.find { |e| e < ofs + size }
            return false if !lower
            return lower + @changes[lower].length > ofs
        end

        def nextChange(ofs)
            return ofs if changed?(ofs,1)
            return @changes.keys.find { |e| e > ofs }
        end

        def checkRange(ofs, size)
            raise "Wrong offset: "+ofs.to_s if ofs < 0 || ofs >= @bytes.length
            raise "Byte range overflow: " + ((ofs + size)-@bytes.length).to_s if ofs + size > @bytes.length
        end

        def bufWrite(buf, str, index)
            return buf[0,index] + str +buf[index+str.length,-1]
        end

        def change(ofs, bytes)
            mode(HOW_ORIGINAL)
            checkRange(ofs, bytes.length)
            if changed?(ofs,bytes.length)
                lower = @changes.keys.reverse.find { |e| e < ofs + size }
                strt = [lower, ofs].min()
                en = [lower+@changes[lower].length, ofs+bytes.length].max()
                buf = "\0" * (en-strt)
                bufWrite(buf, @changes[lower], lower - strt)
                bufWrite(buf, bytes, ofs - strt)
                if (strt!=lower)
                    @changes.delete(ofs)
                end
                @changes[strt] = buf
            else
                @changes[ofs] = bytes
            end
            @changes = Hash[@changes.sort]
        end

        def revertChange(ofs)
            raise sprintf("Change not found at: ") if !@changes[ofs]
            mode(HOW_ORIGINAL)
            @changes.delete(ofs)
            @changes = Hash[@changes.sort]
        end

        def revertChanges()
            @changes.keys.each{|ofs|
                revertChange(ofs)
            }
        end

        def curcol() return @mode == HOW_ORIGINAL ? COL_ORIGINAL : COL_CHANGED end

        def colVal(ofs, size)
            fmt = "%#{size*2}.#{size*2}X"
            u = size == 2 ? "v" : V
            return colStr( sprintf(fmt, getData(ofs, size).unpack(u)[0]) , changed?(ofs,size))
        end

        def colStr(str, cond)
            str = sprintf("%4.4X", str) if !str.is_a?(String)
            return str if !cond
            return @col.color(curcol(), str)
        end

        def reset()
            removeAppend()
            revertChanges()
        end


        def getData(ofs, size)
            checkRange(ofs, size)
            return @bytes[ofs,size]
        end


        def parseHow(how)
            return HOW_CHANGED if !how || how == HOW_CHANGED
            return HOW_ORIGINAL if how == HOW_ORIGINAL
            return HOW_ORIGINAL if how[0] == 'o' || how[0] == 'O'
            return HOW_CHANGED
        end

        def print(what, how)
            wr = HexWriter.new(0)
            res = hex(wr, 0, 0x100, how)
            wr.finish()
            return true
        end


        def hex(writer, ofs, size, how)
            mode(parseHow(how))
            col = curcol()
            return size if ofs > @bytes.length
            while size > 0
                if ofs>=@realSize
                    sz = [size, @bytes.length - ofs].min
                    if sz
                        writer.addBytes(@bytes[ofs, sz], col)
                        size -= sz
                    end
                    return size
                end
                x = nextChange(ofs)
                x = @realSize if !x
                sz = [size, x-ofs].min
                if sz
                    writer.addBytes(@bytes[ofs, sz], nil)
                    size -= sz
                    ofs += sz
                end
                return 0 if size == 0
                if @changes[x]
                    sz = [size, @changes[x].length].min
                    if sz
                        writer.addBytes(@bytes[ofs, sz], col)
                        size -= sz
                        ofs += sz
                    end
                end
            end
        end

    end

end
