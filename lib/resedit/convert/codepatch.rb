module Resedit

    class CodePatch
        FMT_BINARY = 0
        FMT_HEXSTRING = 1

        class Chunk
            NOP = "\x90"
            attr_reader :data, :ofs, :size, :format

            def initialize(data, format, splitter=NOP)
                splitter.force_encoding(Encoding::ASCII_8BIT)
                @data, @format = data, format
                @ofs, @size = [], []
                ofs=0
                data.split(splitter).each{ |part|
                    @ofs += [ofs]
                    @size += [part.length()]
                    ofs += part.length+1
                }
            end

            def addr(idx, adr)
                adr[0] += @ofs[idx]
                return adr
            end

            def hexdata()
                @data.each_byte.map { |b| sprintf("%02X",b) }.join
            end

            def value(idx, size, adr = nil, rep = "\xFF\xFF\xFF\xFF")
                NOP.force_encoding(Encoding::ASCII_8BIT)
                rep.force_encoding(Encoding::ASCII_8BIT)
                ret = data[@ofs[idx], @size[idx]]
                if adr and rep
                    #replace with seg:ofs
                    ret.gsub!(rep, mkadr(adr))
                end
                raise "Code is bigger #{ret.length()} than expected #{size}" if ret.length>size
                while ret.length()<size
                    ret += NOP
                end
                if @format == CodePatch::FMT_HEXSTRING
                    ret = ret.each_byte.map { |b| sprintf("%02X",b) }.join
                end
                return ret
            end

            def mkadr(adr)
                ret = (adr[0]&0xFF).chr + ((adr[0]>>8)&0xFF).chr
                ret += (adr[1]&0xFF).chr + ((adr[1]>>8)&0xFF).chr
                return ret
            end

        end

        def self.loadPatch(fname, format = FMT_HEXSTRING, chunksplit="\x90\x90\x90\x90\x90")
            chunksplit.force_encoding(Encoding::ASCII_8BIT)
            bytes = File.read(fname, encoding:Encoding::ASCII_8BIT)
            return bytes.split(chunksplit).each.map{|data| CodePatch::Chunk.new(data, format)}
        end

    end

end
