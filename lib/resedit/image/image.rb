
module Resedit
    
    class Image
        # Abstract image class
        attr_accessor :width, :height
        TYPE_PNG = 'png'
        TYPE_BMP = 'bmp'
        FORMAT_INDEXED = 0
        FORMAT_32BIT = 1


        def fill(color)
            for j in (0..@height-1)
                for i in (0..@width-1)
                    setPixel(i, j, color)
                end
            end
        end


        def hline(y, color)
            for i in (0..@width-1)
                setPixel(i, y, color)
            end
        end


        def vline(x, color)
            for j in (0..@height-1)
                setPixel(x, j, color)
            end
        end


        #abstract interface
        def getPixel(x, y); end
        def setPixel(x, y, color); end

        def save(filename); end

        protected
        def create(width, height, format); end
        def load(filename); end

    end
end