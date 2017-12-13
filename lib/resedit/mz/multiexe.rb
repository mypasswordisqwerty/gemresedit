require 'resedit/classes/exefile'
require 'resedit/mz/mz'
require 'resedit/mz/bw'
require 'resedit/mz/le'

module Resedit

    class Multiexe < ExeFile

        KNOWN_TYPES = {'MZ' => MZ, 'BW' => BW, 'LE' => LE, 'LX' => LE, 'LC'=>LE}

        attr_reader :cur

        def initialize(path, quiet = false)
            @cur = nil
            @parts = []
            super(path, quiet)
        end

        def load(f, fsize)
            cid = 0
            while !f.eof?
                s = f.read(2).unpack('A2')[0]
                f.seek(-2, :CUR)
                #log("Loading part #{s} @ 0x#{f.tell.to_s(16)}")
                raise "Unknown format #{s}" if !KNOWN_TYPES[s]
                obj = KNOWN_TYPES[s].new(nil, @quiet)
                sz = fsize - f.tell()
                obj.load(f, sz, @parts.length>0 ? @parts[-1] : 0 )
                cid = @parts.length() if obj.is_a?(LE)
                @parts += [obj]
            end
            setPart(cid)
        end

        def loadConfig(cfg)
            @parts.each.with_index{|pr, i|
                pr.loadConfig(cfg[i.to_s])
            }
        end

        def dump(out, parts, how=nil)
            prts = eval(parts)
            open(out,"wb"){|f|
                prts.each{|i|
                    pr = @parts[i]
                    pr.header.mode(pr.header.parseHow(how))
                    pr.body.mode(pr.header.parseHow(how))
                    pr.saveFile(f)
                }
            }
        end

        def header; @cur.header end
        def body; @cur.body end
        def env; @cur.env end

        def setPart(id); @cur = @parts[id] end
        def close(); @parts.each{|pr| pr.close()} end

        def print(what, how=nil)
            if what=="parts"
                puts "#{@parts.length} parts:"
                @parts.each.with_index{|pr, i|
                    puts "#{i}: #{pr.class} #{pr}"
                }
                return true
            end
            @cur.print(what, how)
        end
        def hex(ofs, size=nil, how=nil, disp=nil); @cur.hex(ofs, size, how, disp) end
        def hexify(str); @cur.hexify(str) end
        def getValue(value, type); @cur.getValue(value, type) end
        def append(value, type=nil, where=nil); @cur.append(value, type, where) end
        def replace(value, type=nil, where=nil); @cur.replace(value, type, where) end
        def change(ofs, value, disp=nil, type=nil); @cur.change(ofs, value, disp, type) end
        def reloc(ofs, target=nil); @cur.reloc(ofs, target) end
        def relocfind(value, type=nil); @cur.relocfind(value, type) end
        def stringfind(size=nil); @cur.stringfind(size) end
        def dasm(ofs, size=nil, how=nil) @cur.dasm(ofs, size, how) end
        def valueof(str, type); @cur.valueof(str, type) end
        def revert(what); @cur.revert(what) end
        def readRelocated(ofs, size); @cur.readRelocated(ofs, size) end

        def saveConfig()
            cfg = {}
            @parts.each.with_index{|pr, i|
                cfg[i] = pr.saveConfig()
            }
            return cfg
        end

        def saveFile(f)
            @parts.each{|pr| pr.saveFile(f)}
        end

    end

end
