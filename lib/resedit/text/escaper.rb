module Resedit

    class TextEscaper

        STD_TABLE = {0x5C=>"\\\\", 0x0A=>"\\n", 0x0D=>"\\r", 0x09=>"\\t", 0x07=>"\\a", 0x08=>"\\b", 0x0C=>"\\f", 0x0B=>"\\v", 0x1B=>"\\e"}

        def escape(line)
            out=""
            line.each_byte {|b|
                out += _escape(b)
            }
            return out
        end

        def unescape(line); end

        protected

        def tableReplace(str,tbl,numproc=true)
            ntbl={}
            if tbl
                tbl.each{|b,v|
                    ntbl[v[0]]={} if !ntbl[v[0]]
                    ntbl[v[0]][v]=b
                }
            end
            pos=0
            res=""
            while pos < str.length
                val=str[pos]
                inc=1
                if ntbl[val]
                    ntbl[val].each{|v,b|
                        next if str.length < pos+v.length
                        if v==str[pos,v.length]
                            val=b.chr
                            inc=v.length
                            break
                        end
                    }
                end
                if inc==1 && numproc && val=="\\"
                    raise "Bad escape sequence: "+str if str.length < pos+5
                    num = str[pos+1,3]
                    byte = num[0].upcase=="X" ? num[1,2].to_i(16) : num.to_i
                    raise "Bad numeric escape "+num+": "+str if (byte==0 and num!="000" and num!="x00") || byte>255 || byte<0
                    val=byte.chr
                    inc=4
                end
                res += val
                pos += inc
            end
            return res
        end

        def _escape(b); end
    end


    class SlashEscaper < TextEscaper

        def _escape(b)
            return '\\\\' if b==0x5c
            b<0x20 ? sprintf("\\x%02X", b) : b.chr
        end

        def unescape(line)
            tableReplace(line,{0x5C=>"\\\\"})
        end

    end


    class StdEscaper < SlashEscaper

        def _escape(b)
            STD_TABLE[b] ? STD_TABLE[b] : super(b)
        end

        def unescape(line)
            tableReplace(line,STD_TABLE)
        end

    end


    class TableEscaper < TextEscaper

        def initialize(table=nil, stdTable=STD_TABLE)
            @table={}
            if stdTable
                stdTable.each {|b, e|
                    add(b, e)
                }
            end
            if table
                table.each {|b, e|
                    add(b,e)
                }
            end
        end

        def add(byte, esc)
            @table[byte] = esc
        end

        def _escape(b)
            @table[b] ? @table[b] : b.chr
        end

        def unescape(line)
            tableReplace(line,@table,false)
        end

    end

end
