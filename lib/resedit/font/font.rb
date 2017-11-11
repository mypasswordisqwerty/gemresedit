require 'resedit/font/font_char'
require 'resedit/image/image_factory'
require 'resedit/convert/colors'

module Resedit

    class Font
        attr_reader :count, :width, :height, :bpp
        attr_accessor :gridColor, :charColor, :userData, :widthColor, :bgColor

        # charWidth, charHeight, characters count
        def initialize(width, height, count: 256, bpp: 1)
            @width, @height, @count = width, height, count
            @gridColor = 0xFFEEEEEE
            @charColor = 0xFF000000
            @bgColor = 0xFFFFFFFF
            @widthColor = 0xFFFF0000
            @chars = {}
            @bpp = bpp
            @userData = nil
            @colmap = nil
            @valmap = nil
        end

        def buildBppMap()
            return [@bgColor, @charColor] if @bpp==1
            return ColorMap.new(@bgColor, @charColor).mapBpp(@bpp)
        end

        def colorMap(val)
            @colmap = buildBppMap() if !@colmap
            #@puts "#{val} = #{@colmap[val].to_s(16)}"
            return @colmap[val]
        end

        def valueMap(col)
            if !@valmap
                @valmap = Hash[buildBppMap().each_with_index.map {|x,i| [x, i]}] if !@valmap
            end
            val=@valmap[col]
            raise "Wrong color in font #{col.to_s(16)}" if val==nil
            return val
        end

        def setChar(id, data, width=nil, flags=nil)
            width=@width if !width
            @chars[id] = FontChar.new(self, @height, id, data, width, flags)
        end

        def getChar(id)
            @chars[id].data if @chars[id]
        end

        def minChar
            return @chars.keys().min
        end

        def maxChar
            return @chars.keys().max
        end

        def charWidth(id)
            return nil if !@chars[id]
            return @chars[id].realWidth ? @chars[id].realWidth : @width
        end

        def charFlags(id)
            return nil if !@chars[id]
            return @chars[id].flags
        end

        def save(filename)
            rows = @count/16 + (@count%16 == 0 ? 0 : 1)
            img = Resedit.createImage(@width*16+17 , @height*rows+rows+1, filename)
            img.fill(@bgColor)
            #draw grid
            for i in 0..16
                img.vline(i*(@width+1), @gridColor)
            end
            for j in 0..rows
                img.hline(j*(@height+1), @gridColor)
            end
            #draw letters
            @chars.each { |idx,c|
                x = idx%16
                y = idx/16
                x += 1+x*@width
                y += 1+y*@height
                c.draw(img, x, y)
            }
            img.save(filename)
            @colmap = nil
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
                c = FontChar.new(self, height, idx)
                c.scan(img, x, y)
                @chars[c.index] = c if c.data
            end
            @valmap = nil
        end

    end

end
