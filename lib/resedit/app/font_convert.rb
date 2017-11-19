require 'resedit/app/io_commands'

module Resedit

    class FontConvertCommand < ConvertCommand

        def initialize(fname, cmdname='font')
            super(cmdname, fname)
            @font = nil
        end

        def import(inname)
            logd("importing font #{inname} to #{@resname}")
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
            logd("exporting font #{@resname} to #{outname}")
            File.open(@resname, "rb"){|file|
                @font = mkfont(file)
                unpack(file) if @font
            }
            raise "Font not unpacked" if !@font
            @font.save(outname+'.png')
        end


        def mkfont(file)
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
