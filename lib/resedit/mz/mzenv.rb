require 'singleton'

module Resedit

    class MZEnv

        include Singleton

        def set(name,value)
            MZEnv.class_eval{
                define_method(name){ s2i(value) }
            }
        end

        def s2i_nt(str)
            return [s2i(str), true]
        rescue Exception
            return [0, false]
        end

        def s2i(str)
            ss=str.split(':')
            if ss.length == 2
                return (s2i(ss[0]) << 4) + s2i(ss[1])
            end
            return eval(str, binding())
        end

    end

end
