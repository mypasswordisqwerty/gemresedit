require 'resedit/font/font_char'
require 'resedit/image/image_factory'

module Resedit

    class Font
        attr_reader :count, :width, :height
        attr_accessor :gridColor, :charColor

        # charWidth, charHeight, characters count
        def initialize(width, height, count=256)
            @width, @height, @count = width, height, count
            @gridColor = 0xFFEEEEEE
            @charColor = 0xFF000000
            @bgColor = 0xFFFFFFFF
            @chars = {}
        end

        def setChar(id, data)
            @chars[id] = FontChar.new(@width, @height, id, data)
        end

        def getChar(id)
            @chars[id].data if @chars[id]
        end

        def save(filename)
            rows = @count/16 + (@count%16 == 0 ? 0 : 1)
            img = Resedit.createImage(@width*16+17 , @height*rows+rows+1, filename)
            img.fill(@bgColor)
            #draw grid
            for i in 0..16
                img.vline(i*(@width+1), gridColor)
            end
            for j in 0..rows
                img.hline(j*(@height+1), gridColor)
            end
            #draw letters
            @chars.each { |idx,c|
                x = idx%16
                y = idx/16
                x += 1+x*@width
                y += 1+y*@height
                c.draw(img, @charColor, x, y)
            }
            img.save(filename)
        end

        def load(filename)
            img = Resedit.loadImage(filename)
            rows = @count/16 + (@count%16 == 0 ? 0 : 1)
            raise "Wrong image size" if (img.width!=@width*16+17 || img.height!=@height*rows+rows+1)
            for idx in 0..@count-1
                x = idx%16
                y = idx/16
                x += 1+x*@width
                y += 1+y*@height
                c = FontChar.new(width,height,idx)
                c.scan(img, @charColor, x, y)
                @chars[c.index] = c if c.data
            end
        end

    end

end