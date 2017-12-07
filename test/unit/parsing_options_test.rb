require "test_helper"

class ParsingOptionsTest < UnitTestCase
  sub_test_case("parse_git_cococo_options") do
    test("no options") do
      assert_equal(<<EOS, capture2_command("command1"))
OPTIND: 1
autostash:
init:
EOS
    end

    test("--autostash") do
      assert_equal(<<EOS, capture2_command("--autostash", "command1"))
OPTIND: 2
autostash: 1
init:
EOS
    end

    test("--init") do
      assert_equal(<<EOS, capture2_command("--init", "command1"))
OPTIND: 2
autostash:
init: .
EOS
    end

    test("--init=git-init-path") do
      assert_equal(<<EOS, capture2_command("--init=path/to/init", "command1"))
OPTIND: 2
autostash:
init: path/to/init
EOS
    end

    data(short_option: "-h",
         long_option: "--help")
    test("--help") do |option|
      assert_match(/\AUsage: /, capture2_command(option, "command1"))
    end
  end

  private

  def capture2_command(*arguments)
    stdout, stderr, status = *Open3.capture3("sh", stdin_data: <<STDIN)
. #{COMMAND_PATH}
#{test_method_name} #{Shellwords.join(arguments)}
echo OPTIND: $OPTIND
echo autostash: $autostash
echo init: $init
STDIN
    assert_equal("", stderr)
    assert_equal(0, status.exitstatus)
    return stdout
  end
end
