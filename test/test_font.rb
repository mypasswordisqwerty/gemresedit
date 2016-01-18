require 'minitest/autorun'
require 'resedit'

class FontTest < Minitest::Unit::TestCase

    def test_char
        ltr = Resedit::FontChar.new(4,4,1)
        
    end
  
  def test_save_load
    fnt = Resedit::Font.new(4,4,256)
    ltr = [0,0,0,1, 0,0,1,0, 0,1,0,0, 1,1,1,1]
    fnt.setChar(12,ltr)
    fnt.save('font.png')
    fnt = Resedit::Font.new(4,4,256)
    fnt.load('font.png')
    assert_equal ltr, fnt.getChar(12)
    assert_equal nil, fnt.getChar(13)
    assert_equal nil, fnt.getChar(11)
  end

end