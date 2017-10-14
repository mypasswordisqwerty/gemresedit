require 'minitest/autorun'
require 'resedit'

class FontTest < Minitest::Test

    def test_save_load
        fnt = Resedit::Font.new(4,4,256)
        ltr = [0,0,0,1, 0,0,1,0, 0,1,0,0, 1,1,1,1]
        fnt.setChar(12,ltr)
        fnt.save('test.png')
        fnt = Resedit::Font.new(4,4,256)
        fnt.load('test.png')
        assert_equal ltr, fnt.getChar(12)
        assert_nil fnt.getChar(13)
        assert_nil fnt.getChar(11)
    end

end
