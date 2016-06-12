require 'resedit/app/io_commands'

module Resedit

class FontConvertCommand < ConvertCommand

    def initialize(ext)
        super('font', ext)
    end

    def import(resname, inname)
    end


    def export(resname, outname)
        fnt = nil
        logd("exporting font #{resname} to #{outname}")
        File.open(resname, "rb"){|file|
            fnt = unpack(file, resname)
        }
        raise "Font not unpacked" if !fnt
        fnt.save(outname+'.png')
    end
    

    def pack(file, name)
        raise "Not implemented."
    end

    def unpack(file, name)
        raise "Not implemented."
    end

end

end