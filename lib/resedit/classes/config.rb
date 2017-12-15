require 'json'

module Resedit

    class Config

        attr_accessor :cfg
        def initialize(fname, section=nil)
            @fname = fname
            @section = section ? section : []
            @section = [@section] if !@section.is_a?(Array)
            @cfg = load()
            @section.each{|s|
                @cfg = (@cfg[s] or {})
            }
        end

        def [](nm); @cfg[nm] end
        def []=(nm, value); @cfg[nm]=value end
        def each(&block);@cfg.each(&block) end
        def length; @cfg.length end

        def enter(section, createOnAbsent = true)
            section = [section] if !section.is_a?(Array)
            section.each{|s|
                raise "Config section not found #{s} at #{@section}" if !@cfg[s] && !createOnAbsent
                @cfg = @cfg[s] or {}
                @section += [s]
            }
        end

        def enterOnFile(path)
            ret = nil
            ent = ''
            @cfg.each{|k, _|
                fn = File.join(path, k)
                ret = fn if File.exists?(fn)
                ent = k if ret
                break if ret
            }
            raise "Config not found for files at #{path}" if !ret
            enter(ent, false)
            return ret
        end

        def load();
            File.exists?(@fname) ? JSON.parse(File.read(@fname)) : {}
        end

        def save()
            if @section.length>0
                c = load()
                cur = c
                @section[0..-2].each{|s|
                    cur[s] = {} if !cur[s]
                    cur = cur[s]
                }
                cur[@section[-1]]=@cfg
            else
                c = @cfg
            end
            open(@fname, "w"){|f|
                f.write(JSON.pretty_generate(c))
            }
        end

    end

end
