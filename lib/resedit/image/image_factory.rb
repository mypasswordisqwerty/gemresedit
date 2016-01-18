require 'resedit/image/png_image'
require 'resedit/image/image'

module Resedit
    
    module_function

    def createImage(width, height, type=Image::TYPE_PNG, format=Image::FORMAT_INDEXED)
        type = type[-3..-1] if type.length>3
        case type
        when Image::TYPE_PNG
            img = PngImage.new()
        else
            raise "Unknown format #{type}"
        end
        img.create(width, height, format)
        return img
    end

        
    def loadImage(filename)
        ext = filename[-3..-1].downcase()
        case ext
        when Image::TYPE_PNG
            img=PngImage.new()
        else
            raise "Unknown file format #{filename}"
        end
        img.load(filename)
        return img
    end

end