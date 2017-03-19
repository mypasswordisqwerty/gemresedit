require 'resedit/app/io_commands'

module Resedit

    class TextConvertCommand < ConvertCommand

        def initialize(fname)
            super('text', fname)
            @font = nil
            addOption('format','f',nil,'output file format')
            addOption('encodinc','e',nil,'output file encoding')
        end

        def import(inname)
            logd("importing text #{inname} to #{@resname}")
            back = backup()
            File.open(back,"rb"){|file|
                @font = mkfont(file)
                @font.load(inname+'.png')
                StringIO.open("","w+b"){|stream|
                    pack(file, stream)
                    stream.seek(0)
                    File.open(@resname,"wb"){|out|
                        out.write(stream.read())
                    }
                }
            }
        end


        def export(outname)
            logd("exporting txet #{@resname} to #{outname}")
            File.open(@resname, "rb"){|file|
                @text = mktext(file, @params['format'], @params['encoding'])
                unpack(file) if @text
            }
            raise "Text not unpacked" if !@text
            @text.save(outname)
        end

        def mktext(file, format, encoding)
            raise "Not implemented."
        end

        def pack(file, outstream)
            raise "Not implemented."
        end

        def unpack(file)
            raise "Not implemented."
        end

    end

end
