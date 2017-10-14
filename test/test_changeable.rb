require 'minitest/autorun'
require 'resedit'

class ChangeableTest < Minitest::Test

    def test_inserts
        c = Resedit::Changeable.new('word')
        c.insert(0, 'a ')
        c.mode(Resedit::Changeable::HOW_ORIGINAL)
        assert_equal('word', c.bytes)
        c.mode(Resedit::Changeable::HOW_CHANGED)
        assert_equal('a word', c.bytes)
        c = Resedit::Changeable.new('word')
        c.insert(4,' of')
        assert_equal('word of', c.bytes)
        c = Resedit::Changeable.new('word')
        c.insert(3,'l')
        assert_equal('world', c.bytes)
    end

    def test_multiinserts
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

    def test_changes
        c = Resedit::Changeable.new('word')
        c.change(0,'h')
        assert_equal('hord', c.bytes)
        c.change(2,'n')
        assert_equal('hond', c.bytes)
        c.change(3,'g')
        assert_equal('hong', c.bytes)
        assert_equal({0=>["w", "h"], 2=>["rd", "ng"]}, c.getChanges())
    end

    def test_undo
        c = Resedit::Changeable.new('word')
        c.insert(0, 'a ')
        c.undo(0)
        assert_equal('word', c.bytes)
        assert_equal({}, c.getChanges())
        c.insert(4,' of')
        c.undo(4)
        assert_equal('word', c.bytes)
        assert_equal({}, c.getChanges())
        c.change(0,'h')
        c.change(2,'n')
        c.change(3,'g')
        c.undo(0)
        c.undo(2)
        assert_equal('word', c.bytes)
        assert_equal({}, c.getChanges())
        c.insert(0, 'a ')
        c.change(0,'h')
        c.change(2,'n')
        c.insert(4,' of')
        c.change(3,'g')
        c.revert('all')
        assert_equal('word', c.bytes)
        assert_equal({}, c.getChanges())
    end

    def test_save_load
        c = Resedit::Changeable.new('word')
        c.insert(0, 'a ')
        c.change(0,'h')
        c.change(2,'n')
        c.insert(4,' of')
        c.change(3,'g')
        ch = c.getChanges()
        cb = c.bytes()
        c.mode(Resedit::Changeable::HOW_ORIGINAL)
        ob = c.bytes()
        io = StringIO.new()
        c.saveChanges(io)
        c = Resedit::Changeable.new(cb)
        io.seek(0)
        c.loadChanges(io)
        assert_equal(cb, c.bytes)
        assert_equal(ch, c.getChanges())
        c.mode(Resedit::Changeable::HOW_ORIGINAL)
        assert_equal(ob, c.bytes)
    end

    def test_hex
        c = Resedit::Changeable.new('word')
        c.insert(3, 'l')
        c.insert(0, 'a ')
        c.insert(7, ' of')
        c.change(3, 'i')
        h = Resedit::HexWriter.new(0)
        assert_equal(11, c.hex(h,0,21, 'c'))
        assert_equal(5, c.hex(h,0,9, 'o'))
        puts
        h.finish()
        puts
    end


end
