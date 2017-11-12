module Resedit

    class BitStream

        def initialize(bytes=nil, chunksize=1)
            @bytes = bytes ? bytes : ''
            @chunksize = chunksize
            @bytes.force_encoding(Encoding::ASCII_8BIT)
            @buf = 0
            @bsize = 0
            @pos = 0
        end

        def eof?; @pos>=@bytes.length end

        def read(bits)
            while @bsize < bits
                for _ in 1..@chunksize
                    @buf |= (@pos<@bytes.length ? (@bytes[@pos].ord & 0xFF) : 0) << @bsize
                    @pos += 1
                    @bsize += 8
                end
            end
            mask = (1 << bits) - 1
            ret = @buf & mask
            @buf >>= bits
            @bsize -= bits
            return ret
        end

        def write(val, bits)
        end

        def finish()
        end

    end
end
