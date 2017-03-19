require 'minitest/autorun'
require 'resedit'

class EscapesTest < Minitest::Unit::TestCase

    STR = "A\r\n\t B \a\b C\\\\ \x190D\\n"

    def test_slash
        e=Resedit::SlashEscaper.new()
        req="A\\x0D\\x0A\\x09 B \\x07\\x08 C\\\\\\\\ \\x190D\\\\n"
        s=e.escape(STR)
        s2=e.unescape(s)
        assert_equal req,s
        assert_equal STR,s2
    end

    def test_std
        e=Resedit::StdEscaper.new()
        req="A\\r\\n\\t B \\a\\b C\\\\\\\\ \\x190D\\\\n"
        s=e.escape(STR)
        s2=e.unescape(s)
        assert_equal req,s
        assert_equal STR,s2
    end


    def test_table
        e=Resedit::TableEscaper.new({0x30=>'\zero'})
        req="A\\r\\n\\t B \\a\\b C\\\\\\\\ \x19\\zeroD\\\\n"
        s=e.escape(STR)
        s2=e.unescape(s)
        assert_equal req,s
        assert_equal STR,s2
    end

end
