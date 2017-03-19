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

        attr_reader :tree

        def initialize(zeroLeft, reverseBitsInByte=false)
            @tree=Huffman::Node.new()
            @zeroLeft, @reverseBits=zeroLeft,reverseBitsInByte
        end

        def leafTable(recalc=false)
            if @recalc || !@leafTbl
                tbl=@tree.getLeafs(@zeroLeft ? '0' : '1', @zeroLeft ? '1' : '0')
                @leafTbl={}
                tbl.each{|k,v|
                    @leafTbl[k.length]={} if !@leafTbl[k.length]
                    @leafTbl[k.length][k.to_i(2)]=v
                }
            end
            return @leafTbl
        end

        def debug()
            tbl=leafTable()
            info="---huffman table---\n"
            bts={}
            tbl.keys.sort.each{|sz|
                tbl[sz].each{|k,v|
                    fmt="0x%02X\t%2d\t%0"+sz.to_s+"b\n"
                    info+=sprintf(fmt,v,sz,k)
                    if not bts[v]
                        bts[v]=1
                    else
                        bts[v]+=1
                    end
                }
            }
            info+=sprintf("---%d bytes---\n",bts.length)
            for i in 0..255
                if !bts[i]
                    info+=sprintf("0x%02X - ABSENT\n",i)
                else
                    info+=sprintf("0x%02X - %d times\n",i, bts[i]) if bts[i]!=1
                end
            end
            App.get().logd(info)
        end

        def decode(bitstream, endl=0)
            res=''
            tbl=leafTable()
            max=tbl.keys.max
            pos=0
            byte=bitstream[pos].ord
            bytelen=8
            buf=0
            buflen=0
            while true
                buf<<=1
                buflen+=1
                raise "Huffman decode length overflow" if buflen>max
                buf|=byte & 1
                byte>>=1
                bytelen-=1
                if tbl[buflen] && tbl[buflen][buf]
                    return res if tbl[buflen][buf]==endl
                    res+=tbl[buflen][buf].chr
                    buf=0
                    buflen=0
                end

                next if bytelen>0
                pos+=1
                break if pos>=bitstream.length
                bytelen=8
                byte=bitstream[pos].ord
                byte = sprintf("%08b",byte).reverse.to_i(2) if @reverseBits
            end
            return res
        end

        def encode(bytes)
        end

    end

end
