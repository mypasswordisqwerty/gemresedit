require 'resedit/text/text_format'

module Resedit

    class FormatXml < TextFormat

        def initialize(encoding)
            super('utf-8')
        end

        def saveLines(fname, lines, mets)
        end

        def loadLines(fname)
        end

    end

end
