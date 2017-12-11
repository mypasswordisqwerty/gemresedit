require 'json'

module Resedit

    class Config

        attr_accessor :cfg
        def initialize(fname, section=nil)
            @fname, @section = fname, section
            @cfg = load()
            @cfg = (@cfg[@section] or {}) if @section
        end

        def [](nm); @cfg[nm] end
        def []=(nm, value); @cfg[nm]=value end

        def load();
            File.exists?(@fname) ? JSON.parse(File.read(@fname)) : {}
        end

        def save()
            if @section
                c = load()
                c[@section] = @cfg
            else
                c = cfg
            end
            open(@fname, "w"){|f|
                f.write(JSON.pretty_generate(c))
            }
        end

    end

end
