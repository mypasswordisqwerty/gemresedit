module Resedit

    class BitConverter

        def self.bits2Bytes(bits, width)
            i=0
            res=[]
            while i<bits.length
                buf=0
                cw=0
                bsz=0
                while cw<width
                    if bsz==0
                        buf = bits[i]
                        i+=1
                        bsz=8
                    end
                    bsz-=1
                    cw+=1
                    res << ((buf>>bsz) & 1)
                end
            end
            return res
        end

        def self.bytes2Bits(bytes, rwidth, bwidth)
            res=[]
            for i in 0..(bytes.length/rwidth)-1
                row=bytes[i*rwidth..i*rwidth+rwidth-1]
                while row.length < bwidth*8
                    row << 0
                end
                b=0
                for j in 0..row.length-1
                    b <<= 1
                    b |= row[j]
                    if (j+1)%8==0
                        res << (b & 0xFF)
                        b=0
                    end
                end
            end
            return res
        end

    end

end
