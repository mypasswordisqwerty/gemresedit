require 'resedit/app/app'
module Resedit

    class Huffman

        class Node
            attr_accessor :value, :parent, :left, :right

            def initialize(value=nil, parent=nil)
                @value=value
            end

            def addNode(isLeft,value=nil)
                n=Node.new(value)
                if isLeft
                    @left=n
                else
                    @right=n
                end
                return n
            end

            def addLeft(value=nil)
                addNode(true, value)
            end

            def addRight(value=nil)
                addNode(false, value)
            end

            def getLeafs(leftS,rightS,path='')
                return {path=>@value} if @value
                l=@left.getLeafs(leftS, rightS, path+leftS)
                r=@right.getLeafs(leftS, rightS, path+rightS)
                return l.merge(r)
            end

        end


        class Balancer
            attr_reader :huff
            def initialize(huff)
                @huff = huff
                @tbl = {}
            end

            def addData(bytes)
                bytes.each_byte{|b|
                    @tbl[b] = 0 if !@tbl[b]
                    @tbl[b] += 1
                }
            end

            def balanceValues()
            end

            def balanceTree()
                raise "Not implemented."
            end
        end


        attr_reader :tree

        def initialize(zeroLeft, reverseBitsInByte=false)
            @tree=Huffman::Node.new()
            @zeroLeft, @reverseBits = zeroLeft,reverseBitsInByte
        end

        def decodeTable(recalc=false)
            if @recalc || !@decodeTbl
                tbl = @tree.getLeafs(@zeroLeft ? '0' : '1', @zeroLeft ? '1' : '0')
                @decodeTbl = {}
                tbl.each{|k,v|
                    @decodeTbl[k.length] = {} if !@decodeTbl[k.length]
                    @decodeTbl[k.length][k.to_i(2)] = v
                }
            end
            return @decodeTbl
        end

        def encodeTable(recalc=false)
            if @recalc || !@encodeTbl
                tbl = @tree.getLeafs(@zeroLeft ? '0' : '1', @zeroLeft ? '1' : '0')
                @encodeTbl = {}
                tbl.each{|k,v|
                    @encodeTbl[v] = [k.reverse.to_i(2), k.length]
                }
            end
            return @encodeTbl
        end


        def balancer()
            return Huffman::Balancer.new(self)
        end

        def debug()
            tbl=decodeTable()
            info="---huffman table---\n"
            bts={}
            tbl.keys.sort.each{|sz|
                tbl[sz].each{|k,v|
                    fmt = "0x%02X\t%2d\t%0" + sz.to_s + "b\n"
                    info += sprintf(fmt,v,sz,k)
                    if not bts[v]
                        bts[v] = 1
                    else
                        bts[v] += 1
                    end
                }
            }
            info += sprintf("---%d bytes---\n",bts.length)
            for i in 0..255
                if !bts[i]
                    info+=sprintf("0x%02X - ABSENT\n", i)
                else
                    info+=sprintf("0x%02X - %d times\n", i, bts[i]) if bts[i]!=1
                end
            end
            App.get().logd(info)
        end

        def revbyte(byte)
            return byte if !@reverseBits
            return sprintf("%08b", byte).reverse.to_i(2)
        end

        def decode(bitstream, endl=0)
            res = ''
            tbl = decodeTable()
            max = tbl.keys.max
            pos = 0
            byte = bitstream[pos].ord
            bytelen = 8
            buf = 0
            buflen = 0
            while true
                buf <<= 1
                buflen += 1
                raise "Huffman decode length overflow" if buflen>max
                buf |= byte & 1
                byte >>= 1
                bytelen -= 1
                if tbl[buflen] && tbl[buflen][buf]
                    return res if tbl[buflen][buf] == endl
                    res += tbl[buflen][buf].chr
                    buf = 0
                    buflen = 0
                end

                next if bytelen>0
                pos += 1
                break if pos >= bitstream.length
                bytelen = 8
                byte = revbyte(bitstream[pos].ord)
            end
            return res
        end

        def encode(bytes, endl=0)
            if endl != nil && bytes[-1] != endl
                bytes += endl.chr
            end
            res = ''
            tbl = encodeTable()
            byte = 0
            bytelen = 0
            bytes.each_byte{|b|
                raise sprintf("No byte in encode table: %02X", b)  if !tbl[b]
                val = tbl[b][0]
                for _ in 0..tbl[b][1]-1
                    byte |= ((val & 1) << bytelen)
                    val >>= 1
                    bytelen += 1
                    if bytelen == 8
                        res += revbyte(byte).chr
                        bytelen = 0
                        byte = 0
                    end
                end
            }
            res += revbyte(byte).chr if bytelen > 0
            return res
        end

    end

end
