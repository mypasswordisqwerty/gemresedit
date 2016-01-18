module Resedit

    class FontChar
        attr_accessor :index, :data
        
        def initialize(width, height, index, data=nil)
            @width, @height, @index = width, height, index
            @data=data if (data && data.length==width*height)
        end

        def maxBound
            _max=0
            for j in 0..@height-1
                for i in _max+1..@width
                    if hasPixel(i-1,j)
                        _max=i
                        return _max if _max==@width
                    end
                end
            end
            _max
        end

        def hasPixel(x, y)
            @data[y*@width+x] != 0
        end

        def draw(image, color, x, y)
            for j in 0..@height-1
                for i in 0..@width-1
                    image.setPixel(x+i, y+j, color) if hasPixel(i,j)
                end
            end
        end

        def scan(image, color, x, y)
            @data=[0]*@width*@height
            _hasData = false
            for j in 0..@height-1
                for i in 0..@width-1
                    if image.getPixel(x+i, y+j) ==color
                        @data[j*@width+i]= 1
                        _hasData = true
                    end
                end
            end
            @data=nil if (!_hasData)
            return @data!=nil
        end

    end

end