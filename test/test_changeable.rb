require 'minitest/autorun'
require 'resedit'

class ChangeableTest < Minitest::Test

    def _test_inserts
        c = Resedit::Changeable.new('word')
        c.insert(0, 'a ')
        assert_equal('word', c.orig)
        assert_equal('a word', c.changed)
        assert_equal('a word', c.bytes)
        c = Resedit::Changeable.new('word')
        c.insert(4,' of')
        assert_equal('word of', c.bytes)
        c = Resedit::Changeable.new('word')
        c.insert(3,'l')
        assert_equal('world', c.bytes)
    end

    def _test_multiinserts
        c = Resedit::Changeable.new('word')
        c.mode(Resedit::Changeable::HOW_ORIGINAL)
        c.insert(0, 'a ')
        c.insert(3, 'l')
        c.insert(4, ' of')
        c.mode(Resedit::Changeable::HOW_CHANGED)
        assert_equal('a world of', c.bytes)

        c = Resedit::Changeable.new('word')
        c.mode(Resedit::Changeable::HOW_ORIGINAL)
        c.insert(4, ' of')
        c.insert(3, 'l')
        c.insert(0, 'a ')
        c.mode(Resedit::Changeable::HOW_CHANGED)
        assert_equal('a world of', c.bytes)

        c = Resedit::Changeable.new('word')
        c.mode(Resedit::Changeable::HOW_ORIGINAL)
        c.insert(3, 'l')
        c.insert(4, ' of')
        c.insert(0, 'a ')
        c.mode(Resedit::Changeable::HOW_CHANGED)
        assert_equal('a world of', c.bytes)

        c = Resedit::Changeable.new('word')
        c.insert(0, 'a ')
        c.insert(5, 'l')
        c.insert(7, ' of')
        assert_equal('a world of', c.bytes)

        c = Resedit::Changeable.new('word')
        c.insert(4, ' of')
        c.insert(3, 'l')
        c.insert(0, 'a ')
        assert_equal('a world of', c.bytes)

        c = Resedit::Changeable.new('word')
        c.insert(3, 'l')
        c.insert(0, 'a ')
        c.insert(7, ' of')
        assert_equal('a world of', c.bytes)
        c = Resedit::Changeable.new('word')
        c.insert(3, 'l')
        c.insert(5, ' of')
        c.insert(0, 'a ')
        assert_equal('a world of', c.bytes)
    end

    def test_other
        c = Resedit::Changeable.new('word')
        c.insert(3, 'l')
        c.insert(0, 'a ')
        c.insert(7, ' of')
        #c.change(3, 'i')
        h = Resedit::HexWriter.new(0)
        c.hex(h,0,10, Resedit::Changeable::HOW_CHANGED)
        c.hex(h,0,4, Resedit::Changeable::HOW_ORIGINAL)
        h.finish
    end


end
