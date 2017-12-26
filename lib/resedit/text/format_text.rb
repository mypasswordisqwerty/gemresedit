
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
                    l.force_encoding('utf-8')
                    f.write(l)
                    f.write("\n")
                }
            }
        end

        def loadLines(fname)
            lns=[]
            open(fname+".txt", "r:"+@encoding+":utf-8").each_line {|line|
                lns += [line.chomp]
            }
            lns=lns[0..-2] if lns.last == ""
            return lns
        end


    end

end
