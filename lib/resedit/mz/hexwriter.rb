require 'resedit/app/app'

module Resedit

    class HexWriter

        attr_accessor :written

        def initialize(addr)
            @written = 0
            @charsInLine = 0x10
            @addr = addr
            @col = App::get().col
            @size = 0
            @line = nil
            @cline = ''
            @chr = ''
            @cchr = ''
            @pcol = nil
            @segments = nil
        end

        def setSegments(segments)
            @segments = segments.sort.reverse
        end

        def addrFormat()
            add = ''
            if @segments
                seg = @addr >> 4
                min = @segments.find{|e| e <= seg}
                min = 0 if !min
                add = sprintf(" %4.4X:%4.4X", min, @addr-(min << 4))
            end
            res = sprintf("%8.8X%s | ", @addr, add)
            @addr += @charsInLine
            return res
        end


        def addBytes(bytes, color=nil)
            bytes.each_byte{|b| addChar(b, color)}
        end

        def procColored()
            @line += @col.color(@pcol, @cline)
            @chr += @col.color(@pcol, @cchr)
            @cline = ''
            @cchr = ''
        end

        def buildLine()
            procColored() if @pcol
            puts @line+" | "+@chr
            @line = nil
            @chr=''
            @size = 0
        end

        def addChar(c, color = nil)
            c = c.ord
            @line = addrFormat if !@line
            procColored if color != @pcol && @pcol
            if !color
                @line += sprintf("%2.2X ",c)
                @chr += (c<0x20 || c>0x7E) ? '.' : c.chr
            else
                @cline += sprintf("%2.2X ",c)
                @cchr += (c<0x20 || c>0x7E) ? '.' : c.chr
            end
            @pcol = color
            @size += 1
            @written += 1
            if @size == @charsInLine
                buildLine()
            end
        end

        def finish()
            return if @size == 0
            procColored() if @pcol
            @line += "   " * (@charsInLine - @size)
            buildLine()
        end
    end

end
