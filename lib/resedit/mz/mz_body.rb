require 'resedit/mz/changeable'

module Resedit

    class MZBody < Changeable

        def initialize(mz, file, size)
            super(mz, file, size)
        end

        def print(what, how)
            return false
        end

    end
end
