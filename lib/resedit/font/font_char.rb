module Resedit

    class FontChar
        attr_accessor :index, :data, :realWidth, :flags

        def initialize(font, height, index, data=nil, realWidth=nil, flags=nil)
            @font = font
            @width = font.width
            @height, @index = height, index
            @realWidth=realWidth
            @flags = flags
            @data=data if (data && data.length==@width*height)
        end

        def hasPixel(x, y); @data[y*@width+x] != 0 end

        def valueAt(x,y); @data[y*@width+x] end

        def draw(image, x, y)
            for j in 0..@height-1
                for i in 0..@width-1
                    #p "#{@index} #{@width} #{@height} #{i} #{j} #{valueAt(i,j)}"
                    image.setPixel(x+i, y+j, @font.colorMap(valueAt(i,j))) if hasPixel(i,j)
                end
            end
            if @realWidth
                image.setPixel(x+@realWidth, y, @font.widthColor)
            end
            if @flags && @flags.length>0
                for i in 0..@flags.length-1
                    image.setPixel(x+@realWidth, y+i+1, @flags[i])
                end
            end
        end

        def readFlags(image, x, y)
            empty = true
            flags = []
            for i in 0..@height-2
                col = image.getPixel(x, y+i)
                if col==@font.bgColor || col==@font.gridColor
                    next
                end
                empty=false
                flags[i] = col
            end
            return nil if empty
            return flags
        end


        def scan(image, x, y)
            wColor = @font.widthColor
            bgColor = @font.bgColor
            @data=[0]*@width*@height
            @realWidth = nil
            width = @width
            _hasData = false
            for j in 0..@height-1
                for i in 0..width-1
                    col=image.getPixel(x+i, y+j)
                    if col == wColor
                        @realWidth = i
                        width = @realWidth
                        break
                    elsif col != bgColor
                        @data[j*@width+i] = @font.valueMap(col)
                        _hasData = true
                    end
                end
            end
            fx = x + (@realWidth ? @realWidth : @width)
            @flags = readFlags(image, fx, y+1)
            @data=nil if !_hasData
            return @data!=nil
        end

    end

end
