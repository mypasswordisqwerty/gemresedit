require 'resedit/text/format_text'
require 'builder'
require 'rexml/document'

module Resedit

    class FormatXml < TextFormat

        def initialize(encoding)
            super('utf-8')
        end

        def saveLines(fname, lines, meta)
            open(fname+".xml", "w:"+@encoding) {|f|
                xml=Builder::XmlMarkup.new(:indent => 2 , :target=>f)
                xml.instruct! :xml, :encoding => @encoding
                xml.body {|b|
                    lines.each.with_index{|l,i|
                        mt = {'id' => i}
                        mt.update(meta[i]) if meta[i]
                        b.text(l, mt)
                    }
                }
            }
        end

        def loadLines(fname)
            hs={}
            open(fname+".xml", "r:"+@encoding) {|f|
                doc=REXML::Document.new(f)
                doc.elements.each("body/text"){|e|
                    hs[e.attributes['id']] = e.text
                }
            }
            raise "No data in xml" if !hs.length
            lns=[]
            for i in 0..hs.length-1
                raise "Text not found: "+i if !hs[i]
                lns+=[ hs[i] ]
            end
            return lns
        end

    end

end
