require "test_helper"

class EscapingTest < UnitTestCase
  def self.test_escaping
    test("") do |data|
      arguments, expected = *data
      assert_equal(expected, capture2_command(*arguments))
    end
  end

  sub_test_case("escape_quote_argument") do
    data(without_quote_charactor: %w[foo foo],
         with_quote_charactor: %w[abc'def abc'\''def])
    test_escaping
  end

  sub_test_case("escape_one_argument") do
    data(no_special_charactors: %w[foo foo],
         with_space_charactor: ["foo bar", "'foo bar'"],
         with_dollar_charactor: %w[foo$bar 'foo$bar'],
         with_double_quote_charactor: %w[foo"bar 'foo"bar'],
         with_quote_charactor: %w[abc'def 'abc'\''def'],
         with_quote_charactor_in_begin_of_argument: %w['foo ''\''foo'],
         with_quote_charactor_in_end_of_argument: %w[foo' 'foo'\'''])
    test_escaping
  end

  sub_test_case("escape_command_line") do
    data(one_argument: [%w[foo], "foo"],
         two_arguments: [%w[foo bar], "foo bar"],
         two_arguments_with_space_charactor: [["foo", "ba r"], "foo 'ba r'"],
         two_arguments_with_quote_charactor: [["foo", "ba'r"], "foo 'ba'\\''r'"])
    test_escaping
  end

  private

  COMMAND_PATH = EXE_PATH / "git-cococo"

  def test_method_name
    return self.class.name[/(?<=::).*\z/]
  end

  def capture2_command(*arguments)
    stdout, stderr, status = *Open3.capture3("sh", stdin_data: <<STDIN)
. #{COMMAND_PATH}
#{test_method_name} #{Shellwords.join(arguments)}
STDIN
    assert_equal("", stderr)
    assert_equal(0, status.exitstatus)
    return stdout
  end
end
