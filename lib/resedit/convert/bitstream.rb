module Resedit

    class BitStream

        attr_reader :bytes

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
                    raise "End of stream" if @pos==@bytes.length
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

        def write(val, bits=8)
            mask = (1 << bits) - 1
            @buf |= (val & mask) << @bsize
            @bsize += bits
            if @bsize >= @chunksize*8
                for _ in 1..@chunksize
                    @bytes += (@buf & 0xFF).chr
                    @bsize -= 8
                    @buf>>=8
                end
            end
        end

        def finish()
            if @bsize!=0
                write(0, @chunksize*8-@bsize)
            end
            return @bytes
        end

    end
end
