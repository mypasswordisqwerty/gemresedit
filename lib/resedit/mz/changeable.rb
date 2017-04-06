require 'resedit/app/colorizer'
require 'resedit/mz/hexwriter'
require 'resedit/mz/mzenv'

module Resedit

    class Changeable
        HOW_CHANGED = 0
        HOW_ORIGINAL = 1
        COL_CHANGED = Colorizer::YELLOW
        COL_ORIGINAL = Colorizer::PURPLE

        attr_reader :mz, :bytes, :add, :changes, :realSize, :realOfs

        def initialize(mz, file, size)
            @mz = mz
            @bytes = file.read(size)
            @realOfs = 0
            @realSize = @bytes.size
            @add = nil
            @changes = {}
            @c2 = []
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
                @add = @bytes[@realSize..-1] if @bytes.length > @realSize
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
            mode(HOW_ORIGINAL)
            pos = @bytes.length + (@add ? @add.length : 0)
            @add = @add ? @add + bytes : bytes
            return pos
        end

        def removeAppend()
            mode(HOW_ORIGINAL)
            @add = nil
            @bytes = @bytes[0,@realSize]
            return true
        end


        def changed?(ofs, size=2)
            return true if ofs+size > @realSize
            lower = @c2.find { |e| e < (ofs + size) }
            return false if !lower
            return lower + @changes[lower].length > ofs
        end

        def nextChange(ofs)
            return ofs if changed?(ofs,1)
            return @c2.reverse.find { |e| e > ofs }
        end

        def checkRange(ofs, size)
            raise "Wrong offset: "+ofs.to_s if ofs < 0 || ofs >= @bytes.length
            raise "Byte range overflow: " + ((ofs + size)-@bytes.length).to_s if ofs + size > @bytes.length
        end

        def bufWrite(buf, str, index)
            return buf[0, index] + str + buf[index+str.length .. -1]
        end

        def change(ofs, bytes)
            if ofs > @realSize
                mode(HOW_CHANGED)
                checkRange(ofs, bytes.length)
                bytes.each_byte{|b|
                    @bytes[ofs] = b.chr
                    ofs += 1
                }
                return ofs
            end
            mode(HOW_ORIGINAL)
            checkRange(ofs, bytes.length)
            if changed?(ofs,bytes.length)
                lower = @c2.find { |e| e < ofs + bytes.length }
                strt = [lower, ofs].min()
                en = [lower+@changes[lower].length, ofs+bytes.length].max()
                buf = ("\0" * (en-strt)).force_encoding(Encoding::ASCII_8BIT)
                buf = bufWrite(buf, @changes[lower], lower - strt)
                buf = bufWrite(buf, bytes, ofs - strt)
                @changes.delete(lower)
                @c2.delete(lower)
                change(strt, buf)
            else
                @changes[ofs] = bytes
                @c2 = @changes.keys.reverse
            end
            return ofs
        end

        def revertChange(ofs)
            raise sprintf("Change not found at: ") if !@changes[ofs]
            mode(HOW_ORIGINAL)
            @changes.delete(ofs)
            @c2 = @changes.keys.reverse
            return ofs
        end

        def revert(what)
            mode(HOW_ORIGINAL)
            if what=='all'
                removeAppend()
                @changes = {}
                @c2=[]
                return true
            end
            if what == 'append' || what==@realSize+@realOfs
                removeAppend()
                return true
            end
            return false if !@changes[what-@realOfs]
            revertChange(what-@realOfs)
            return true
        end


        def curcol() return @mode == HOW_ORIGINAL ? COL_ORIGINAL : COL_CHANGED end

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
            mode(parseHow(how))
            if what=="changes"
                @changes.each{|ofs,bts|
                    bts = getData(ofs, bts.length)
                    printf("%08X: %s\n", ofs+@realOfs, colStr(bts.bytes.map { |b| sprintf("%02X",b) }.join))
                }
                if @add
                    printf("%08X: %s\n", @realSize+@realOfs, colStr(@add.bytes.map { |b| sprintf("%02X",b) }.join))
                end
                puts
                return true
            end
            return false
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

        def saveData(file)
            mode(HOW_CHANGED)
            file.write(@bytes)
        end

        def saveChanges(file)
            mode(HOW_CHANGED)
            file.write([@realSize, @changes.length].pack('VV'))
            @changes.each{|c,bts|
                file.write([c, bts.length].pack('VV'))
                file.write(bts)
            }
        end

        def loadChanges(file)
            mode(HOW_CHANGED)
            @realSize,clen=file.read(8).unpack('VV')
            @add = @bytes[@realSize..-1] if @bytes.length > @realSize
            @bytes = @bytes[0, @realSize]
            for i in 0..clen-1
                ofs, bts = file.read(8).unpack('VV')
                @changes[ofs] = file.read(bts)
            end
            @c2 = @changes.keys.reverse
            mode(HOW_ORIGINAL)
        end

    end

end
