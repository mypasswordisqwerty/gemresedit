require 'resedit/mz/changeable'
begin
    require 'crabstone'
    include Crabstone
    $nocrabstone = false
rescue LoadError
    $nocrabstone = true
end


module Resedit

    class MZBody < Changeable

        attr_reader :segments, :appSeg

        def initialize(mz, file, size)
            super(mz, file, size)
            @segments = Set.new()
            for i in 0..@mz.header.info[:NumberOfRelocations]-1
                r = @mz.header.getRelocation(i)
                @segments.add(r[1])
                val = segData(r, 2).unpack('v')[0]
                @segments.add(val)
            end
            @appSeg = (@realSize >> 4) + 1
            puts @appSeg
        end


        def seg2Linear(a,s) (s << 4) + a end

        def seg4Linear(linear)
            linear >>= 4
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
            return "None" if ofs>@bytes.length
            return getData(ofs, size) if !isStr
            return colVal(ofs, size)
        end



        def removeAppend()
            @segments.each{|s|
                @segments.delete(s) if (s << 4) > @realSize
            }
            super()
        end

        def revert(what)
            @realOfs = @mz.header.headerSize()
            super(what)
        end

        def append(bytes)
            mode(HOW_ORIGINAL)
            res = 0
            addseg = false
            if !@add
                addseg = true
                res = 0x10 - (@realSize % 0x10)
                res = 0 if res == 0x10
                bytes = ("\x90" * res).force_encoding(Encoding::ASCII_8BIT) + bytes if res > 0
            end
            res += super(bytes)
            @mz.header.setCodeSize(@bytes.length + @add.length)
            seg = linear2seg(res)
            res = [res, seg]
            if addseg
                raise "Segs not match" if (@appSeg << 4) != res[0]
                @segments.add(@appSeg)
                res += [ [ 0, @appSeg] ]
            end
            return res
        end

        def print(what, how)
            if what=="header"
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
                            printf("%08X %04X:%04X%s\n",i.address, seg[0], seg[1], inst)
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
