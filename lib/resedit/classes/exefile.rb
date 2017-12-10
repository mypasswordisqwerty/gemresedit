require 'resedit/classes/changeable'
require 'resedit/classes/hexwriter'
require 'resedit/classes/env'
require 'json'

begin
    require 'crabstone'
    include Crabstone
    $nocrabstone = false
rescue LoadError
    $nocrabstone = true
end

module Resedit

    class ExeHeader < Changeable
        BLK = 0x200
        PARA = 0x10
        HDRDESCR = [:Magic]
        HDRUNPACK = "v*"

        attr_reader :info, :exe

        def initialize(exe, file, fsize)
            raise "Not EXE file" if fsize < self.class::HSIZE
            @exe = exe
            super(file, self.class::HSIZE)
            @_infoOrig = loadInfo()
            @_info = nil
            @info = @_infoOrig
            @relocFix = 0
            raise "Not EXE file" if self.class::MAGIC != @info[:Magic] && (!self.class::MAGIC.is_a?(Array) || !self.class::MAGIC.include?(@info[:Magic]))
            loadTables(file)
            loadTail(file)
        end

        def mode(how)
            super(how)
            if @mode == HOW_ORIGINAL
                @info = @_infoOrig
            else
                @_info = loadInfo() if  !@_info
                @info = @_info
            end
        end


        def change(ofs, bytes)
            super(ofs, bytes)
            @_info = nil if (ofs < HSIZE)
        end


        def loadInfo()
            v = getData(0, self.class::HSIZE).unpack(self.class::HDRUNPACK)
            ret = self.class::HDRDESCR.map.with_index { |x, i| [x, v[i]] }.to_h
            return ret
        end
        def loadTables(file); end
        def loadTail(file);
            addData(file, headerSize() - self.class::HSIZE)
        end


        def setInfo(field, values, pack="v*")
            raise "Unknown header field #{field}" if !self.class::HDRDESCR.include?(field)
            values = [values] if !values.is_a?(Array)
            change(self.class::HDRDESCR.index(field)*2, values.pack(pack))
        end

        def setBodySize(size); setFileSize(size + headerSize()) end

        def headerSize(); self.class::HSIZE end

        def print(what, how)
            return false if what!="header"
            mode(parseHow(how))
            ofs=0
            wsz = @exe.wsize
            @info.each{|k,v|
                printf("%20s:\t%s\n", k.to_s, colStr(v, changed?(ofs,wsz)))
                ofs+=2
            }
            puts
            return true
        end

        def setHeaderSize(size); raise "NotImplemented" end
        def fileSize(); raise "NotImplemented"  end
        def setFileSize(size); raise "NotImplemented" end
        def entry(size); raise "NotImplemented" end
    end


    class ExeBody < Changeable

        attr_reader :exe

        def initialize(exe, file, size)
            @exe = exe
            super(file, size)
            @addsz = 0
        end

        def removeAppend()
            mode(HOW_CHANGED)
            undo(0) if @root.obuf.length==0
            @addsz = 0
        end

        def revert(what)
            super(what)
            @addsz = 0
        end

        def printDasm(inst, str)
            printf("%08X %s\n",inst.address, str)
        end

        def hex(wr, ofs, size, how)
            wr.addressFormatter = self
            if how && (how[0]='r' || how[0]='R')
                wr.addBytes(readRelocated(ofs, size))
                return
            end
            super(wr, ofs, size, how)
        end

        def formatAddress(raw)
            return sprintf("%08X", raw)
        end

        def dasm(ofs, size, how, mode)
            raise "Crabstone gem required to disasm." if $nocrabstone
            relocated = false
            if how && how[0]='r' || how[0]='R'
                relocated = true
                how = nil
            end
            mode(parseHow(how))
            cs = Disassembler.new(ARCH_X86, mode==16 ? MODE_16 : MODE_32)
            begin
                while true
                    begin
                        d = relocated ? readRelocated(ofs, size) : getData(ofs, size)
                        cs.disasm(d, ofs).each {|i|
                            bts = i.bytes.map { |b| sprintf("%02X",b) }.join
                            inst = colStr(sprintf("%14s\t%s\t%s", bts, i.mnemonic, i.op_str), changed?(i.address, i.bytes.length))
                            printDasm(i, inst)
                        }
                        break
                    rescue
                        ofs-=1
                    end
                end
            ensure
                cs.close()
            end
        end

        def raw2addr(ofs); raise "Not implemented" end
        def addr2raw(addr); raise "Not implemented" end
        def append(bytes, where=nil); raise "NotImplemented" end
        def addrFormatter(hofs); nil end
        def readRelocated(ofs, size); raise "NotImplemented" end
    end

    class ExeFile
        HDRCLASS = nil
        BODYCLASS = nil
        CFGEXT = ".mzcfg.json"
        MODE = 16

        attr_reader :header, :body, :fname, :path, :name, :env

        def initialize(path=nil, quiet = false)
            @quiet = quiet
            @path=path
            @env = Env.new(self)
            if @path!=nil
                @path = path.downcase()
                fsize = File.size(path)
                open(@path,"rb:ascii-8bit"){|f|
                    load(f, fsize)
                }
                if File.exist?(@path+CFGEXT)
                    cfg = JSON.parse(File.read(@path+CFGEXT))
                    loadConfig(cfg)
                end
                @fname = File.basename(@path)
                @name = File.basename(@path, ".*")
            end
        end

        def wsize; self.class::MODE/8 end

        def load(f, fsize, prev=nil)
            @header = self.class::HDRCLASS.new(self, f, fsize)
            @body = self.class::BODYCLASS.new(self, f, @header.fileSize() - @header.headerSize())
            @env.set(:entry, @header.entry())
            @env.set(:append, sprintf("0"))
        end

        def loadConfig(cfg)
            cfg = cfg[self.class.name]
            raise "Wrong config: #{self.class.name} expected" if !cfg
            @header.loadConfig(cfg)
            @body.loadConfig(cfg)
        end

        def close(); end
        def log(fmt, *args); App::get().log(fmt, *args) if !@quiet end
        def s2i(str) return @env.s2i(str) end


        def is?(id)
            id = id.downcase
            return id == @path || id == @fname || id == @name
        end

        def print(what, how=nil)
            puts "Header changes:" if what=="changes"
            res = @header.print(what, how)
            puts "Code changes:" if what=="changes"
            res |= @body.print(what, how)
            raise "Don't know how to print: " + what if !res
        end


        def hex(ofs, size=nil, how=nil, disp=nil)
            ofs = ofs ? s2i(ofs) : 0
            size = size ? s2i(size) : 0x100
            isfile = disp && (disp[0]=='f' || disp[0]=='F') ? true : false
            wr = HexWriter.new(ofs)
            hsz = 0
            if isfile
                @header.mode(@header.parseHow(how))
                hsz = @header.headerSize()
                size = @header.hex(wr, ofs, size, how) if ofs < hsz
                ofs -= hsz
                ofs = 0 if ofs < 0
                wr.addr = 0
            end
            @body.hex(wr, ofs, size, how) if size > 0
            wr.finish()
        end

        def hexify(str); @header.hexify(str) end

        def getValue(value, type)
            s = @env.value2bytes(value, type)
            return s.force_encoding(Encoding::ASCII_8BIT)
        end


        def append(value, type=nil, where=nil)
            where = s2i(where) if where
            res = @body.append(getValue(value,type), where)
            s = ""
            res.each{|a|
                if a.is_a?(Array)
                    s += sprintf(" %04X:%04X", a[1], a[0])
                else
                    s += sprintf(" %08X", a)
                end
            }
            log("Appended at %s",s)
            return res
        end


        def replace(value, type=nil, where=nil)
            @body.removeAppend()
            return append(value, type, where)
        end


        def change(ofs, value, disp=nil, type=nil)
            ofs = s2i(ofs)
            isfile = disp && (disp[0]=='f' || disp[0]=='F') ? true : false
            value = getValue(value, type)
            if isfile
                res = @header.change(ofs,value)
            else
                res = @body.change(ofs,value) + @header.headerSize()
            end
            log("Change added at %08X", res) if res
        end

        def reloc(ofs); raise "NotImplemented" end

        def readRelocated(ofs, size); @body.readRelocated(ofs, size) end

        def dasm(ofs, size=nil, how=nil)
            ofs = s2i(ofs ? ofs : "entry")
            size = size ? s2i(size) : [0x20, @body.bytes.length-ofs].min
            @body.dasm(ofs, size, how, self.class::MODE)
        end


        def valueof(str, type)
            puts "value of " + str + " is:"
            p getValue(str, type).unpack("H*")
        end


        def revert(what)
            wid = @env.s2i_nt(what)
            what = wid[1] ? wid[0] : what
            res = @header.revert(what)
            res |= @body.revert(what)
            raise "Don't know how to revert: "+what if !res
            log("Reverted")
        end

        def saveConfig()
            cfg = {}
            cfg['header'] = @header.saveChanges()
            cfg['body'] = @body.saveChanges(f)
            return {self.class.name => cfg}
        end

        def saveFile(f)
            @header.saveData(f)
            @body.saveData(f)
        end

        def save(filename)
            raise "Filename expected." if !filename
            open(filename, "wb:ascii-8bit"){|f|
                saveFile(f)
            }
            open(filename+CFGEXT, "w"){|f|
                f.write(JSON.pretty_generate(saveConfig()))
            }
        end
    end

end
