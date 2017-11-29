require "test_helper"

class EscapingTest < UnitTestCase
  sub_test_case("escape_quote_argument") do
    test("foo") do
      assert_equal("foo", capture2_command("foo"))
    end

    test("abc\'def") do
      assert_equal("abc\'\\\'\'def", capture2_command("abc\'def"))
    end
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
