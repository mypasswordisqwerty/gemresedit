require 'resedit/image/image'
require 'chunky_png'

module Resedit

    class PngImage < Image

        def initialize
            @img = nil
        end
        
        def getPixel(x, y)
            col = @img[x, y]
            return (col<<24) | (col>>8)
        end
        
        def setPixel(x, y, color)
            @img[x, y] =  (color<<8) | (color>>24)
        end

        def create(width, height, format)
            @width, @height = width, height            
            @img = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
        end

        def save(filename)
            filename+='.png' if filename[-4..-1].downcase() != '.png'
            @img.save(filename)
        end

        def load(filename) 
            @img = ChunkyPNG::Image.from_file(filename)
            @width = @img.width
            @height = @img.height
        end
    end

end