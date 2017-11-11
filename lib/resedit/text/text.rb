require 'resedit/text/format_text'
require 'resedit/text/format_xml'
require 'resedit/text/escaper'

module Resedit

    class Text

        attr_reader :lines, :format
        attr_accessor :userData, :encoding, :escaper, :formatter, :meta
        TYPE_TXT = 'txt'
        TYPE_XML = 'xml'

        def initialize(format=TYPE_TXT,encoding=nil)
            @encoding = encoding
            format=TYPE_TXT if !format
            setFormat(format)
            @escaper = StdEscaper.new()
            @lines = []
            @meta={}
        end

        def setFormat(format)
            if format == TYPE_TXT
                @format = format
                @formatter=FormatTxt.new(@encoding)
            elsif format == TYPE_XML
                @format = format
                @formatter=FormatXml.new(@encoding)
            else
                raise "Unsupported format " + format
            end
        end

        def addLine(line, meta = nil)
            line.encode!("utf-8",@encoding) if @encoding
            line.force_encoding('utf-8')
            @lines += [line]
            @meta[@lines.length-1]=meta
        end

        def getLine(id)
            line = @lines[id]
            line.encode!(@encoding) if @encoding
            return line
        end

        def save(filename)
            nl=@lines
            if @escaper
                nl=[]
                @lines.each{|l|
                    nl += [@escaper.escape(l)]
                }
            end
            @formatter.saveLines(filename, nl, @meta)
        end

        def load(filename, count=nil)
            @lines = @formatter.loadLines(filename)
            raise "Wrong lines count: #{filename} #{count} #{@lines.length}" if count && count!=@lines.length
            if @escaper
                nl=[]
                @lines.each {|l|
                    nl += [@escaper.unescape(l)]
                }
                @lines = nl
            end
        end

    end

end
