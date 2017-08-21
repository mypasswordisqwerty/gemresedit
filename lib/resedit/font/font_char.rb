module Resedit

    class FontChar
        attr_accessor :index, :data, :realWidth, :flags

        def initialize(width, height, index, data=nil, realWidth=nil, flags=nil)
            @width, @height, @index = width, height, index
            @realWidth=realWidth
            @flags = flags
            @data=data if (data && data.length==width*height)
        end

        def hasPixel(x, y)
            @data[y*@width+x] != 0
        end

        def draw(image, color, x, y, wColor)
            for j in 0..@height-1
                for i in 0..@width-1
                    image.setPixel(x+i, y+j, color) if hasPixel(i,j)
                end
            end
            if @realWidth
                image.setPixel(x+@realWidth, y, wColor)
            end
            if @flags && @flags.length>0
                for i in 0..@flags.length-1
                    image.setPixel(x+@realWidth, y+i+1, @flags[i])
                end
            end
        end

        def readFlags(image, x, y, bgcolors)
            empty = true
            flags = []
            for i in 0..@height-2
                flags += [bgcolors[0]]
                col = image.getPixel(x, y+i)
                if bgcolors.include?(col)
                    next
                end
                empty=false
                flags[i] = col
            end
            return nil if empty
            return flags
        end


        def scan(image, color, x, y, wColor, bgcolors)
            @data=[0]*@width*@height
            @realWidth = nil
            _hasData = false
            for j in 0..@height-1
                for i in 0..@width-1
                    col=image.getPixel(x+i, y+j)
                    if col==color
                        @data[j*@width+i]= 1
                        _hasData = true
                    end
                    if col ==wColor
                        @realWidth = i
                    end
                end
            end
            fx = x + (@realWidth ? @realWidth : @width)
            @flags = readFlags(image, fx, y+1, bgcolors)
            @data=nil if !_hasData
            return @data!=nil
        end

    end

end
