require 'resedit/classes/exefile'

module Resedit

    class MZHeader < ExeHeader
        MAGIC = 0x5A4D
        HSIZE = 0x1C
        HDRDESCR = [:Magic, :BytesInLastBlock, :BlocksInFile, :NumberOfRelocations, :HeaderParagraphs, :MinExtraParagraphs, :MaxExtraParagraphs,
                    :SS, :SP, :Checksum, :IP, :CS, :RelocTableOffset, :OverlayNumber]

        attr_reader :relocFix

        def initialize(exe, file, size)
            super(exe, file, size)
            @relocFix = 0
            @newOfs = false
            if @info[:RelocTableOffset]>=0x40
                @newOfs = getData(0x3C, 2).unpack("v")[0]
            end
        end

        def entry; sprintf("%04X:%04X", @info[:CS], @info[:IP]) end

        def setFileSize(size)
            mode(HOW_CHANGED)
            mod = size % BLK
            setInfo(:BytesInLastBlock, [mod, size / BLK + (mod ? 1 : 0)])
        end

        def rebuildHeader(codesize)
            mode(HOW_ORIGINAL)
            ss = @info[:SS]
            cs = @info[:CS]
            sz = fileSize()-headerSize()
            codesize += PARA - codesize % PARA if codesize % PARA!=0
            changeSize(sz + codesize + headerSize())
            paras = codesize / PARA
            setInfo(:SS, ss+paras)
            setInfo(:CS, cs+paras)
            for i in 0..@info[:NumberOfRelocations]-1
                rel = getRelocation(i)
                rel[1] += paras-@relocFix
                fix(@info[:RelocTableOffset] + i * 4, rel.pack('vv'))
            end
            mode(HOW_CHANGED)
            @relocFix = paras
            MZEnv.instance().set(:relocFix, paras.to_s)
            return codesize
        end

        def addHeaderSize(size)
            mode(HOW_CHANGED)
            paras = size/16 + (size%16 == 0 ? 0 : 1)
            insert(headerSize(), "\x00" * (paras * PARA))
            setFileSize(fileSize() + paras * PARA)
            setInfo(:HeaderParagraphs, @info[:HeaderParagraphs] + paras)
            mode(HOW_CHANGED)
        end

        def loadChanges(cfg)
            super(cfg)
            mode(HOW_ORIGINAL)
            ocs = @info[:CS]
            mode(HOW_CHANGED)
            ncs = @info[:CS]
            @relocFix = ncs - ocs
        end

        def headerSize(); @info[:HeaderParagraphs] * PARA end

        def fileSize()
            return @newOfs if @newOfs
            sz = @info[:BlocksInFile] * BLK
            if @info[:BytesInLastBlock] != 0
                sz -= BLK - @info[:BytesInLastBlock]
            end
            return sz
        end


        def getRelocation(idx)
            raise "Wrong relocation index " if idx<0 || idx >= @info[:NumberOfRelocations]
            return getData(@info[:RelocTableOffset] + idx * 4, 4).unpack('vv')
        end

        def setRelocation(idx, data)
            raise "Wrong relocation index " if idx<0 || idx >= @info[:NumberOfRelocations]
            change(@info[:RelocTableOffset] + idx * 4, data.pack('vv'))
        end


        def freeSpace(middle = false)
            return @info[:RelocTableOffset] - HSIZE  if middle
            return headerSize() - HSIZE - @info[:NumberOfRelocations] * 4
        end

        def setSpaceForRelocs(count)
            add = count - @info[:NumberOfRelocations]
            return if add<=0
            add -= freeSpace()/4
            return if add<=0
            addHeaderSize(add*4)
            setInfo(:NumberOfRelocations, count)
            mode(HOW_CHANGED)
        end

        def addReloc(ofs, trg)
            mode(HOW_CHANGED)
            #check relocation exists
            for i in 0..@info[:NumberOfRelocations]-1
                rel = getRelocation(i)
                if @exe.body.seg2Linear(rel[0], rel[1]) == ofs
                    return false
                end
            end
            #add relocation
            setSpaceForRelocs(@info[:NumberOfRelocations]+1)
            val = @exe.body.linear2seg(ofs)
            setRelocation(@info[:NumberOfRelocations], val)
            return true
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
                s = colStr(sprintf("%d (%X)", fsz,fsz), changed?(2, 4))
                printf("mz file size: %s\treal file size: %d (0x%X)\n", s, @fsize, @fsize)
                printf("header size: %s\n", colStr(hsz, changed?(8, 2)))
                printf("code size: %s\n", colStr(fsz - hsz, @mz.body.changed?(0)))
                printf("reloc table size: %s\n", colStr(@info[:NumberOfRelocations] * 4, changed?(6, 2)))
                printf("free space in header: before relocs 0x%X,  after relocs 0x%X\n", freeSpace(true), freeSpace())
                printf("reloc fix: 0x%X\n", @relocFix)
                return true
            end
            @exe.body.mode(@mode)
            if what == "reloc"
                ofs = @info[:RelocTableOffset]
                for i in 0..@info[:NumberOfRelocations]-1
                    s1 = colVal(ofs,2)
                    s2 = colVal(ofs+2,2)
                    s3 = @exe.body.segData(getRelocation(i), 2, true)
                    printf("%08X\t%s:%s\t= %s\n", ofs, s2, s1, s3)
                    ofs += 4
                end
                return true
            end
            return super(what, how)
        end

    end


    class MZBody < ExeBody

        attr_reader :segments

        def initialize(exe, file, size)
            super(exe, file, size)
            @segments = nil
        end

        def reloadSegments()
            @segments = Set.new()
            for i in 0..@exe.header.info[:NumberOfRelocations]-1
                r = @exe.header.getRelocation(i)
                @segments.add(r[1])
                sd = segData(r, 2)
                next if !sd
                val = sd.unpack('v')[0]
                @segments.add(val)
            end
            @msegs = @segments.sort.reverse
        end

        def patchRelocs(add)
            @segments = Set.new()
            for i in 0..@exe.header.info[:NumberOfRelocations]-1
                r = @exe.header.getRelocation(i)
                @segments.add(r[1])
                ofs = seg2Linear(r[0], r[1])
                val = getData(ofs, 2).unpack('v')[0] + add
                fix(ofs, [val].pack('v'))
                @segments.add(val)
            end
            @msegs = @segments.sort.reverse
        end

        def seg2Linear(a,s) (s << 4) + a end

        def seg4Linear(linear)
            linear >>= 4
            reloadSegments() if !@segments
            min = @segments.sort.reverse.find{|e| e <= linear}
            return min ? min : 0
        end


        def linear2seg(linear, inSegments=nil)
            inSegments = [seg4Linear(linear)] if !inSegments
            res = []
            inSegments.each{|s|
                raise sprintf("Linear %X less than segment %04X", inSegments[0], s) if linear < (s<<4)
                a = linear - (s << 4)
                res += [a,s]
            }
            return res
        end


        def segData(reloc, size, isStr=false)
            ofs = seg2Linear(reloc[0], reloc[1])
            return nil if ofs > @root.size()
            return getData(ofs, size) if !isStr
            return colVal(ofs, size)
        end

        def formatAddress(addr)
            @sfix=0
            seg = (addr-@sfix) >> 4
            min = @msegs.find{|e| e <= seg}
            min = 0 if !min
            return sprintf("%08X %04X:%04X", addr, min, addr - @sfix - (min << 4))
        end

        def raw2addr(ofs); linear2seg(ofs) end
        def addr2raw(addr); seg2Linear(addr[0], addr[1]) end


        def append(bytes, where=nil)
            mode(HOW_CHANGED)
            relfix = @exe.header.relocFix
            res = @addsz
            buf = @addsz>0 ? @root.nbuf[0, @addsz] : ''
            buf += bytes
            removeAppend()
            @addsz = buf.length
            sz = @exe.header.rebuildHeader(@addsz)
            insert(0, bytes + "\x00"*(sz-@addsz))
            seg = linear2seg(res)
            res = [res, seg, sz/0x10]
            patchRelocs(sz/0x10 - relfix)
            return res
        end

        def removeAppend()
            mode(HOW_CHANGED)
            undo(0) if @root.obuf.length==0
            @addsz = 0
        end



        def print(what, how)
            if what=="header"
                reloadSegments() if !@segments
                puts "Known segments: " + @segments.sort.map{ |i| sprintf('%04X',i) }.join(", ")
                return true
            end
            return super(what, how)
        end


        def printDasm(inst, str)
            seg = linear2seg(inst.address)
            printf("%08X %04X:%04X%s\n",inst.address, seg[1], seg[0], str)
        end

    end


    class MZ < ExeFile
        HDRCLASS = MZHeader
        BODYCLASS = MZBody
    end

end
