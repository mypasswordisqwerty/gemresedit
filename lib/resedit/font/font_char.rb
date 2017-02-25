module Resedit

    class FontChar
        attr_accessor :index, :data, :realWidth

        def initialize(width, height, index, data=nil, realWidth=nil)
            @width, @height, @index = width, height, index
            @realWidth=realWidth
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
            if @realWidth && @realWidth<@width
                image.setPixel(x+realWidth, y, wColor)
            end
        end

        def scan(image, color, x, y, wColor)
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
            @data=nil if !_hasData
            return @data!=nil
        end

    end

end
