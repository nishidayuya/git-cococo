require "test_helper"

class EscapingTest < Test::Unit::TestCase
  sub_test_case("escape_quote_argument") do
    test("foo") do
      command_path = (EXE_PATH / "git-cococo").expand_path
      stdout, stderr, status = *Open3.capture3("sh", stdin_data: <<STDIN)
. #{command_path}
escape_quote_argument foo
STDIN
      assert_equal("foo", stdout)
      assert_equal("", stderr)
      assert_equal(0, status.exitstatus)
    end

    test("abc\'def") do
      command_path = (EXE_PATH / "git-cococo").expand_path
      stdout, stderr, status = *Open3.capture3("sh", stdin_data: <<STDIN)
. #{command_path}
escape_quote_argument "abc'def"
STDIN
      assert_equal("abc\'\\\'\'def", stdout)
      assert_equal("", stderr)
      assert_equal(0, status.exitstatus)
    end
  end
end
