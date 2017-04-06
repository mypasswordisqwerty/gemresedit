require 'resedit/mz/mz_header'
require 'resedit/mz/mz_body'
require 'resedit/mz/hexwriter'
require 'resedit/mz/mzenv'

module Resedit

    class MZ

        attr_reader :fname, :path, :name, :fsize
        attr_reader :header, :body

        def initialize(path, quiet = false)
            raise "File not specified" if !path
            @quiet = quiet
            @path = path.downcase()
            @fsize = File.size(path)
            open(@path,"rb:ascii-8bit"){|f|
                @header = MZHeader.new(self, f, fsize)
                hsz = @header.headerSize()
                @body = MZBody.new(self, f, @header.fileSize() - hsz)
            }
            @fname = File.basename(@path)
            @name = File.basename(@path, ".*")
            hi = @header.info()
            env().set(:entry, hi[:CS].to_s+":"+hi[:IP].to_s)
            env().set(:append, @body.appSeg)
        end

        def log(fmt, *args)
            App::get().log(fmt, *args) if !@quiet
        end

        def env() return MZEnv.instance() end
        def s2i(str) return MZEnv.instance().s2i(str) end

        def is?(id)
            id = id.downcase
            return id == @path || id == @fname || id == @name
        end

        def print(what, how)
            puts "Header changes:" if what=="changes"
            res = @header.print(what, how)
            puts "Code changes:" if what=="changes"
            res |= @body.print(what, how)
            raise "Don't know how to print: " + what if !res
        end

        def hex(ofs, size, how, disp)
            ofs = ofs ? s2i(ofs) : 0
            size = size ? s2i(size) : 0x100
            isfile = disp && (disp[0]=='f' || disp[0]=='F') ? true : false
            wr = HexWriter.new(ofs)
            how = @header.parseHow(how)
            hsz = 0
            if isfile
                @header.mode(how)
                hsz = @header.headerSize()
                size = @header.hex(wr, ofs, size, how) if ofs < hsz
                ofs -= hsz
                ofs = 0 if ofs < 0
            end
            wr.setSegments(@body.segments, hsz)
            @body.hex(wr, ofs, size, how) if size > 0
            wr.finish()
        end

        def getValue(value, type)
            s = env().value2bytes(value, type)
            return s.force_encoding(Encoding::ASCII_8BIT)
        end

        def append(value,type)
            res = @body.append(getValue(value,type))
            s = ""
            res.each{|a|
                if a.is_a?(Array)
                    s += sprintf(" %04X:%04X", a[1], a[0])
                else
                    s += sprintf(" %08X", a)
                end
            }
            log("Appended at %s",s)
        end

        def replace(value, type)
            @body.removeAppend()
            return append(value,type)
        end

        def change(ofs, value, disp, type)
            ofs = s2i(ofs)
            isfile = disp && (disp[0]=='f' || disp[0]=='F') ? true : false
            value = getValue(value, type)
            if isfile
                res = @header.change(ofs,value)
            else
                res = @body.change(ofs,value) + @header.headerSize()
            end
            log("Change added at %08X", res)
        end

        def dasm(ofs, size, how)
            ofs = s2i(ofs ? ofs : "entry")
            size = size ? s2i(size) : 0x20
            @body.dasm(ofs, size, how)
        end

        def valueof(str, type)
            puts "value of " + str + " is:"
            p getValue(str, type).unpack("H*")
        end

        def revert(what)
            wid = env().s2i_nt(what)
            what = wid[1] ? wid[0] : what
            res = @header.revert(what)
            res |= @body.revert(what)
            raise "Don't know how to revert: "+what if !res
            log("Reverted")
        end

        def save()
        end

        def close()
        end


    end

end
