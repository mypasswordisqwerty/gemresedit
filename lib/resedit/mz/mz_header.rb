require 'resedit/mz/changeable'

module Resedit

    class MZHeader < Changeable
        MAGIC = 0x5a4D
        BLK = 0x200
        PARA = 0x10
        HSIZE = 0x1C

        attr_reader :segments, :info

        def initialize(mz, file, size)
            raise "Not MZ file" if size < HSIZE
            super(mz, file, HSIZE)
            @fsize = size
            @XinfoOrig = loadInfo()
            @Xinfo = nil
            @info = @XinfoOrig
            raise "Not MZ file" if MAGIC != @info[:Magic]
            readMore(file, headerSize() - HSIZE)
            @segments = Set.new()
            for i in 0..@info[:NumberOfRelocations]
                r = getRelocation(i)
                @segments.add(r[1])
            end
        end

        def mode(how)
            super(how)
            if @mode == HOW_ORIGINAL
                @info = @XinfoOrig
            else
                @Xinfo = loadInfo() if  !@Xinfo
                @info = @Xinfo
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


        def setSegments()
            i = info()
            for i in 0..i[:NumberOfRelocations]
                r = relocValue(i)
                @segments.add(r)
            end
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

        def relocValue(idx)
            r = getRelocation(idx)
            @mz.body.mode(@mode)
            data = @mz.body.getData(seg2Linear(r[1], r[0]), 2).unpack('v')[0]
        end


        def seg2Linear(s,a=0) (s << 4) + a end

        def seg4Linear(linear)
            linear >>= 4
            min = @segments.sort.reverse.find{|e| e < linear}
            return min ? min : 0
        end

        def linear2seg(linear, inSegments=nil)
            inSegments = [seg4Linear(linear)] if !inSegments
            res = []
            inSegments.each{|s|
                raise sprintf("Linear %X less than segment %4.4X", inSegments[0], s) if linear < (s<<4)
                a = linear - (s << 4)
                res += [ [s,a] ]
            }
            return res
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
                    puts sprintf("%20s:\t%s", k.to_s, colVal(ofs, 2))
                    ofs+=2
                }
                puts
                fsz = fileSize()
                hsz = headerSize()
                s = colStr(sprintf("%d (%X)", fsz,fsz), changed?(2,4))
                puts sprintf("mz file size: %s\treal file size: %d (0x%X)", s, @fsize, @fsize)
                puts sprintf("header size: %s", colStr(hsz, changed?(8)))
                puts sprintf("code size: %s", colStr(fsz - hsz, @mz.body.add != nil))
                puts sprintf("reloc table size: %s", colStr(@info[:NumberOfRelocations] * 4, changed?(6)))
                puts sprintf("free space in header: before relocs 0x%X,  after relocs 0x%X", freeSpace(true), freeSpace())
                puts "Known segments: " + @segments.map{ |i| sprintf('%4.4X',i) }.join(", ")
                return true
            end
            if what == "reloc"
                ofs = @info[:RelocTableOffset]
                for i in 0..@info[:NumberOfRelocations]
                    r = getRelocation(i)
                    s1 = colVal(ofs,2)
                    s2 = colVal(ofs+2,2)
                    s3 = @mz.body.colVal(seg2Linear(r[1], r[0]),2)
                    puts sprintf("%4.4X:\t%s:%s\t\t=%s", ofs, s2, s1, s3)
                    ofs += 4
                end
                return true
            end
            return false
        end


    end

end
