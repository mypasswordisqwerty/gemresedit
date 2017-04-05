require 'resedit/mz/mz_header'
require 'resedit/mz/mz_body'
require 'resedit/mz/hexwriter'
require 'resedit/mz/mzenv'

module Resedit

    class MZ

        attr_reader :fname, :path, :name, :fsize
        attr_reader :header, :body

        def initialize(path)
            raise "File not specified" if !path
            @path = path.downcase()
            @fsize = File.size(path)
            open(@path,"rb"){|f|
                @header = MZHeader.new(self, f, fsize)
                hsz = @header.headerSize()
                @body = MZBody.new(self, f, @header.fileSize() - hsz)
            }
            @header.change(4, "\x56\x57")
            @header.change(0x1A, "\xAD\xDE")
            @fname = File.basename(@path)
            @name = File.basename(@path, ".*")
            hi = @header.info()
            env().set(:entry, hi[:CS].to_s+":"+hi[:IP].to_s)
            @header.setSegments()
        end

        def env() return MZEnv.instance() end
        def s2i(str) return MZEnv.instance().s2i(str) end

        def is?(id)
            id = id.downcase
            return id == @path || id == @fname || id == @name
        end

        def print(what, how)
            res = @header.print(what, how)
            res |= @body.print(what, how)
            raise "Don't know how to print " + what if !res
        end

        def hex(ofs, size, how, disp)
            ofs = s2i(ofs)
            size = size ? s2i(size) : 0x100
            isfile = disp && (disp[0]=='f' || disp[0]=='F') ? true : false
            wr = HexWriter.new(ofs)
            how = @header.parseHow(how)
            if isfile
                @header.mode(how)
                hsz = @header.headerSize()
                size = @header.hex(wr, ofs, size, how) if ofs < hsz
                ofs -= hsz
                ofs = 0 if ofs < 0
            end
            wr.setSegments(@header.segments)
            @body.hex(wr, ofs, size, how) if size > 0
            wr.finish()
        end

        def append(data)
            @nubody = @nubody ? @nubody+data : data
            @header.addExtended(@nubody.length)
        end

        def reset()
            @header.reset()
            @body.reset()
        end

        def save()
        end

        def close()
        end


    end

end
