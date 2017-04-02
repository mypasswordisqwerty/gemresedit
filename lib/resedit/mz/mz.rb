require 'resedit/mz/mz_info'

module Resedit

    class MZ
        MAGIC = 0x5a4D
        BLK = 0x200
        PARA = 0x10

        class Header
            attr_accessor :magic, :lastBlockBts, :blocks, :relocs, :headerPara, :minExtraPara, :maxExtraPara
            attr_accessor :ss, :sp, :csum, :ip, :cs, :relocOfs, :ovlNum

            def initialize(file)
                @magic = file.read(2).unpack('v')[0]
                raise "Not MZ file" if @magic != MAGIC
                @lastBlockBts, @blocks, @relocs, @headerPara = file.read(8).unpack('v*')
                @minExtraPara, @maxExtraPara = file.read(4).unpack('v*')
                @ss, @sp, @csum, @ip, @cs, @relocOfs, @ovlNum = file.read(14).unpack('v*')
            end

            def fsize()
                sz = @blocks * BLK
                if @lastBlockBts != 0
                    sz -= BLK - @lastBlockBts
                end
                return sz
            end

        end

        class Relocs
            attr_accessor :relocs, :count
            attr_accessor :pspace, :nspace
            def initialize(file, hdrsize, ofs, count)
                @count = count
                @pspace = ofs - 0x1C
                file.read(@pspace) if @pspace > 0
                @relocs = file.read(count * 4).unpack('v*')
                @nspace = hdrsize - (count * 4 + ofs)
                file.read(@nspace) if @nspace > 0
            end

            def getReloc(i)
                raise "Bad index" if i<0 || i >= @count
                return [relocs[i*2], relocs[i*2+1]]
            end
        end

        attr_reader :fname, :path, :name, :fsize
        attr_reader :header, :relocs, :body

        def initialize(path)
            @path = path.downcase()
            @fsize = File.size(path)
            read()
            @fname = File.basename(@path)
            @name = File.basename(@path, ".*")
        end

        def self.s2i(str, throw=true)
            raise "Not implemented" if throw
            return [0,false]
        end

        def is?(id)
            id = id.downcase
            return id == @path || id == @fname || id == @name
        end

        def read()
            open(@path,"rb"){|f|
                @header = Header.new(f)
                hsz = @header.headerPara * PARA
                @relocs = Relocs.new(f, hsz, @header.relocOfs, @header.relocs)
                @body = f.read(@header.fsize() - hsz)
            }
        end

        def info(what)
            MZInfo.new(self, what)
        end

        def save()
        end

        def close()
        end


    end

end
