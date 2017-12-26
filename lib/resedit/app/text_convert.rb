require 'resedit/app/io_commands'
require 'resedit/app/app_command'

module Resedit

    class ITextConvert < AppCommand
        attr_accessor :text
        def initialize(resname, params)
            @resname, @params = resname, params
        end
        def mktext(file, format, encoding); raise "NotImplemented" end
        def expectedLines(file); raise "NotImplemented" end
        def pack(file, outstream); raise "NotImplemented" end
        def unpack(file); raise "NotImplemented" end
    end

    class TextConvertCommand < ConvertCommand


        attr_accessor :text
        def initialize(fname, cmdname='text')
            super(cmdname, fname)
            @text = nil
            addOption('format','f',nil,'output file format')
            addOption('encoding','e',nil,'output file encoding')
        end

        def getInterface(resname, params); self end

        def import(inname)
            @iface = getInterface(@resname, @params)
            logd("importing text #{inname} to #{@resname}")
            back = backup()
            File.open(back,"rb"){|file|
                @iface.text = @iface.mktext(file, @params['format'], @params['encoding'])
                @iface.text.load(inname, @iface.expectedLines())
                StringIO.open("","w+b"){|stream|
                    @iface.pack(file, stream)
                    if stream.length>0
                        stream.seek(0)
                        File.open(@resname,"wb"){|out|
                            out.write(stream.read())
                        }
                    end
                }
            }
        end


        def export(outname)
            @iface = getInterface(@resname, @params)
            logd("exporting text #{@resname} to #{outname}")
            File.open(@resname, "rb"){|file|
                @iface.text = @iface.mktext(file, @params['format'], @params['encoding'])
                @iface.unpack(file) if @iface.text
            }
            raise "Text not unpacked" if !@iface.text
            @iface.text.save(outname)
        end


        def mktext(file, format, encoding)
            return Resedit::Text.new(format, encoding)
        end

        def expectedLines(file); nil end

        def pack(file, outstream)
            raise "Not implemented."
        end

        def unpack(file)
            raise "Not implemented."
        end

    end

end
