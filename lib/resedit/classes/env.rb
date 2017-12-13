require 'ostruct'

module Resedit

    class Env < OpenStruct

        def initialize(owner=nil)
            super()
            @owner = owner
            @mode = @owner ? @owner.class::MODE : 16
        end

        def set(name, value)
            self[name] = s2i(value)
        end

        def s2i_nt(str)
            return [s2i(str), true]
        rescue Exception
            return [0, false]
        end

        def addr2raw16(ss)
            ss[0] = '0x'+ss[0] if ss[0][0,2]!='0x'
            ss[1] = '0x'+ss[1] if ss[1][0,2]!='0x'
            fix = 0
            if ss.length == 3
                raise "Dont known how to #{ss[2]} address" if ss[2]!="fix"
                fix = relocFix
            end
            return ((s2i(ss[0])+fix) << 4) + s2i(ss[1])
        end

        def addr2raw32(ss)
            ss[1] = '0x'+ss[1] if ss[1][0,2]!='0x'
            if ss[0]==''
                return @owner.body.addr2raw(s2i(ss[1]))
            end
            ss[0] = 'seg'+ss[0] if ss[0][0,3]!='seg'
            return eval(ss[0]+"+"+ss[1])
        end

        def s2i(str)
            ss=str.split(':')
            if ss.length == 2 || ss.length == 3
                return @mode==32 ? addr2raw32(ss) : addr2raw16(ss)
            end
            return eval(str, binding())
        end


        def valueHex(s, type)
            s = s[0..-2] if s[-1] == 'h'
            s = s[2..-1] if s[0,2] == '0x'
            return nil if s.length == 0
            sz = type[1]
            sz = s.length / 2 + s.length % 2 if !sz || sz==0
            hx = eval('0x'+s, binding())
            s=""
            for _ in 0..sz-1
                s += sprintf("%02X", hx & 0xFF)
                hx >>= 8
            end
            return valueBytes(s)
        rescue SyntaxError
            return nil
        end

        def valueBytes(str)
            return nil if str[0,2] == '0x' || str[0,2]=='0X'
            return nil if str.length % 2 == 1
            return nil if str[/\H/]
            return [str].pack('H*')
        rescue
            return nil
        end

        def value2bytes(str, type)
            tp = [nil, nil]
            if type && type.length > 0
                tp[0] = type[0]
                t = type[1..-1]
                t = t[1..-1] while t.length > 0 && (t[0]<'0' || t[0]>'9')
                tp[1] = t.to_i
            end
            return str if tp[0] == "s"
            return str+"\x00" if tp[0] == "z"
            if tp[0]=='f' || (File.exists?(str) && !tp[0])
                return File.read(str)
            end
            res = valueBytes(str) if !tp[0] || tp[0] == "b"
            res = valueHex(str, tp) if !res && (!tp[0] || tp[0] == "h")
            res = eval(str, binding()) if !res
            return res if res.is_a?(String)
            res = valueHex(res.to_s(16), tp)
            raise str if res==nil
            return res
        rescue Exception => e
            raise "Bad value: "+e.to_s
        end

    end

end
