
module Resedit

    class TextFormat

        def initialize(encoding)
            @encoding=encoding
        end

        def saveLines(fname, lines, meta); end

        def loadLines(fname); end

    end

    class FormatTxt < TextFormat

        def initialize(encoding)
            super((encoding or 'cp1251'))
        end

        def saveLines(fname, lines, meta)
            open(fname+".txt", "w:"+@encoding) {|f|
                lines.each {|l|
                    f.write(l+"\r\n")
                }
            }
        end

        def loadLines(fname)
            lns=[]
            open(fname+".txt", "r:"+@encoding).each_line {|line|
                lns += [line.chomp]
            }
            lns=lns[0..-2] if lns.last == ""
            return lns
        end


    end

end
