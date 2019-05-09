
module Resedit

    class Color
        attr_accessor :a, :r, :g, :b, :amath

        def initialize(valOrR, g=nil, b=nil, a=0xFF)
            @amath = false
            if g == nil
                @r = (valOrR >> 16) & 0xFF
                @g = (valOrR >> 8) & 0xFF
                @b = valOrR & 0xFF
                @a = (valOrR >> 24) & 0xFF
            else
                @r, @g, @b, @a = valOrR, g, b, a
            end
        end

        def to_s()
            return "[#{@a.to_s(16)} #{@r.to_s(16)} #{@g.to_s(16)} #{@b.to_s(16)}]"
        end

        def to_i()
            return (@a<<24)|(@r<<16)|(@g<<8)|@b
        end

        def add(col)
            @a = [0xFF, @a + col.a].min if @amath
            @r = [0xFF, @r + col.r].min
            @g = [0xFF, @g + col.g].min
            @b = [0xFF, @b + col.b].min
            return self
        end

        def mul(m)
            @a = [0xFF, (@a * m).to_i()].min if @amath
            @r = [0xFF, (@r * m).to_i()].min
            @g = [0xFF, (@g * m).to_i()].min
            @b = [0xFF, (@b * m).to_i()].min
            return self
        end

        def *(m); Color.new(@r,@g,@b,@a).mul(m) end

        def +(col); Color.new(@r,@g,@b,@a).add(col) end

    end

    class ColorMap

        def initialize(from, to)
            @from = Color.new(from)
            @to = Color.new(to)
        end

        def gradient(steps)
            map = [@from.to_i]
            c = steps
            for i in 1..steps-2
                v = 1.0 * i / c
                map << (@from*(1.0-v) + @to*v).to_i
            end
            map << @to.to_i
            #puts map
            return map
        end

        def mapBpp(bpp)
            return gradient(1<<bpp)
        end


    end

end
