require 'singleton'

module Resedit

    class Colorizer
        GRAY = 90
        RED = 91
        GREEN = 92
        YELLOW = 93
        BLUE = 94
        PURPLE = 95
        CYAN = 96
        WHITE = 97

        attr_accessor :on

        include Singleton

        def initialize()
            @on = true
        end

        def color(col, text)
            return text if !@on
            return "\033[#{col}m#{text}\033[0m"
        end

        def gray(text) color(GRAY, text) end
        def red(text) color(RED, text) end
        def green(text) color(GREEN, text) end
        def yellow(text) color(YELLOW, text) end
        def blue(text) color(BLUE, text) end
        def deep(text) color(PURPLE, text) end
        def cyan(text) color(CYAN, text) end
        def white(text) color(WHITE, text) end

    end
end
