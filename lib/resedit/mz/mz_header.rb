require 'resedit/mz/changeable'

module Resedit

    class MZHeader < Changeable
        MAGIC = 0x5a4D
        BLK = 0x200
        PARA = 0x10
        HSIZE = 0x1C

        attr_reader :info

        def initialize(mz, file, size)
            raise "Not MZ file" if size < HSIZE
            super(mz, file, HSIZE)
            @fsize = size
            @_infoOrig = loadInfo()
            @_info = nil
            @info = @_infoOrig
            raise "Not MZ file" if MAGIC != @info[:Magic]
            readMore(file, headerSize() - HSIZE)
        end

        def mode(how)
            super(how)
            if @mode == HOW_ORIGINAL
                @info = @_infoOrig
            else
                @_info = loadInfo() if  !@_info
                @info = @_info
            end
        end

        def change(ofs, bytes)
            super(ofs, bytes)
            @_info = nil if (ofs < HSIZE)
        end

        def loadInfo()
            v = getData(0, HSIZE).unpack('v*')
            return  {:Magic => v[0], :BytesInLastBlock => v[1], :BlocksInFile => v[2], :NumberOfRelocations => v[3],
                     :HeaderParagraphs => v[4], :MinExtraParagraphs => v[5], :MaxExtraParagraphs => v[6],
                     :SS => v[7], :SP => v[8], :Checksum => v[9], :IP => v[10], :CS => v[11],
                     :RelocTableOffset => v[12], :OverlayNumber => v[13]
                     }
        end


        def setCodeSize(size)
            mode(HOW_CHANGED)
            size += headerSize()
            mod = size % BLK
            ch = [mod, size / BLK + (mod ? 1 : 0)]
            change(2, ch.pack('vv'))
        end


        def headerSize()
            return @info[:HeaderParagraphs] * PARA
        end


        def fileSize()
            sz = @info[:BlocksInFile] * BLK
            if @info[:BytesInLastBlock] != 0
                sz -= BLK - @info[:BytesInLastBlock]
            end
            return sz
        end


        def getRelocation(idx)
            raise "Wrong relocation index " if idx<0 || idx>@info[:NumberOfRelocations]
            return getData(@info[:RelocTableOffset] + idx * 4, 4).unpack('vv')
        end


        def freeSpace(middle = false)
            return @info[:RelocTableOffset] - HSIZE  if middle
            return headerSize() - HSIZE - @info[:NumberOfRelocations] * 4
        end

        def print(what, how)
            mode(parseHow(how))
            if what == "header"
                ofs=0
                @info.each{|k,v|
                    printf("%20s:\t%s\n", k.to_s, colVal(ofs, 2))
                    ofs+=2
                }
                puts
                fsz = fileSize()
                hsz = headerSize()
                s = colStr(sprintf("%d (%X)", fsz,fsz), changed?(2,4))
                printf("mz file size: %s\treal file size: %d (0x%X)\n", s, @fsize, @fsize)
                printf("header size: %s\n", colStr(hsz, changed?(8)))
                printf("code size: %s\n", colStr(fsz - hsz, @mz.body.add != nil))
                printf("reloc table size: %s\n", colStr(@info[:NumberOfRelocations] * 4, changed?(6)))
                printf("free space in header: before relocs 0x%X,  after relocs 0x%X\n", freeSpace(true), freeSpace())
                return true
            end
            if what == "reloc"
                ofs = @info[:RelocTableOffset]
                for i in 0..@info[:NumberOfRelocations]-1
                    s1 = colVal(ofs,2)
                    s2 = colVal(ofs+2,2)
                    s3 = @mz.body.segData(getRelocation(i), 2, true)
                    printf("%08X\t%s:%s\t= %s\n", ofs, s2, s1, s3)
                    ofs += 4
                end
                return true
            end
            return super(what, how)
        end


    end

end
