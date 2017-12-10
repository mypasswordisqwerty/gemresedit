require 'resedit/classes/colorizer'

module Resedit

    class HexWriter

        attr_accessor :written, :addressFormatter, :addr

        def initialize(addr, addressFormatter=nil)
            @written = 0
            @charsInLine = 0x10
            @addr = addr
            @col = Colorizer.instance()
            @size = 0
            @line = nil
            @cline = ''
            @chr = ''
            @cchr = ''
            @pcol = nil
            @addressFormatter = addressFormatter
        end

        def addrFormat()
            if @addressFormatter
                res = @addressFormatter.formatAddress(@addr)+" | "
            else
                res = sprintf("%08X | ", @addr)
            end
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
                @line += sprintf("%02X ",c)
                @chr += (c<0x20 || c>0x7E) ? '.' : c.chr
            else
                @cline += sprintf("%02X ",c)
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
