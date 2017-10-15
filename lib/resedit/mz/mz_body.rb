require 'resedit/classes/changeable'

begin
    require 'crabstone'
    include Crabstone
    $nocrabstone = false
rescue LoadError
    $nocrabstone = true
end


module Resedit

    class MZBody < Changeable

        attr_reader :segments, :appSeg, :mz

        def initialize(mz, file, size)
            @mz = mz
            super(file, size)
            @segments = nil
            @addsz = 0
        end

        def reloadSegments()
            @segments = Set.new()
            for i in 0..@mz.header.info[:NumberOfRelocations]-1
                r = @mz.header.getRelocation(i)
                @segments.add(r[1])
                val = segData(r, 2).unpack('v')[0]
                @segments.add(val)
            end
        end

        def patchRelocs(add)
            @segments = Set.new()
            for i in 0..@mz.header.info[:NumberOfRelocations]-1
                r = @mz.header.getRelocation(i)
                @segments.add(r[1])
                ofs = seg2Linear(r[0], r[1])
                val = getData(ofs, 2).unpack('v')[0] + add
                change(ofs, [val].pack('v'))
                @segments.add(val)
            end
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
            #return "None" if ofs > @root.size()
            return getData(ofs, size) if !isStr
            return colVal(ofs, size)
        end


        def removeAppend()
            mode(HOW_CHANGED)
            undo(0) if @root.obuf.length==0
            @addsz = 0
        end

        def revert(what)
            super(what)
            @addsz = 0
        end

        def append(bytes, where=nil)
            mode(HOW_CHANGED)
            res = @addsz
            buf = @addsz>0 ? @root.nbuf[0, @addsz] : ''
            buf += bytes
            removeAppend()
            @addsz = buf.length
            sz = @mz.header.rebuildHeader(@addsz)
            insert(0, bytes + "\x00"*(sz-@addsz))
            seg = linear2seg(res)
            res = [res, seg, sz/0x10]
            patchRelocs(sz/0x10)
            return res
        end


        def print(what, how)
            if what=="header"
                reloadSegments() if !@segments
                puts "Known segments: " + @segments.sort.map{ |i| sprintf('%04X',i) }.join(", ")
                return true
            end
            @realOfs = @mz.header.headerSize()
            return super(what, how)
        end


        def dasm(ofs, size, how)
            raise "Crabstone gem required to disasm." if $nocrabstone
            mode(parseHow(how))
            cs = Disassembler.new(ARCH_X86, MODE_16)
            begin
                while true
                    begin
                        d = getData(ofs,size)
                        cs.disasm(d, ofs).each {|i|
                            seg = linear2seg(i.address)
                            bts = i.bytes.map { |b| sprintf("%02X",b) }.join
                            inst = colStr(sprintf("%14s\t%s\t%s", bts, i.mnemonic, i.op_str), changed?(i.address, i.bytes.length))
                            printf("%08X %04X:%04X%s\n",i.address, seg[1], seg[0], inst)
                        }
                        break
                    rescue
                        ofs-=1
                    end
                end

            ensure
                cs.close()
            end
        end


    end
end
