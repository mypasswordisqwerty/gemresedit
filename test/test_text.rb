require 'minitest/autorun'
require 'resedit'

class TextTest < Minitest::Unit::TestCase

    def test_save_load
        txt = Resedit::Text.new()
        txt.addLine('line1')
        txt.addLine('line2')
        txt.addLine('line3')
        txt.save("test.txt")
        lns=txt.lines
        txt = Resedit::Text.new()
        txt.load("test.txt")

        assert_equal lns, txt.lines
    end

end
