require "test_helper"

class InitialModeTest < IntegrationTestCase
  setup(:prepare_working_path)
  teardown(:destroy_working_path)

  test("run command, git init and commit in current directory") do
    new_file_path = Pathname("new_file.txt")
    command = "git cococo --init append_file #{new_file_path} wrote."
    run_command(command)

    @repository = Rugged::Repository.new(".git")
    assert_git_status([])
    assert_equal("run: #{command}\n", @repository.head.target.message)
    assert_equal(1, @repository.head.log.length)
    assert_equal("wrote.\n", new_file_path.read)
  end

  test("run command in current directory and git init and commit specified directory") do
    command = [
      *%w"git cococo --init=blog sh -c",
      "mkdir blog && append_file blog/2017-10-25-sunny.txt Today is sunny!",
    ]
    run_command(*command)

    repository_path = Pathname("blog")
    @repository = Rugged::Repository.new((repository_path / ".git").to_s)
    assert_git_status([])
    assert_equal("run: #{command[0 .. -2].join(" ")} '#{command[-1]}'\n",
                 @repository.head.target.message)
    assert_equal(1, @repository.head.log.length)
    assert_equal("Today is sunny!\n",
                 (repository_path / "2017-10-25-sunny.txt").read)
  end

  test("cannot use with --autostash option") do
    new_file_path = Pathname("new_file.txt")
    command = "git cococo --autostash --init append_file #{new_file_path} wrote."
    stdout, status = *Open3.capture2(command)
    assert_equal(1, status.exitstatus)
    assert_equal(<<STDOUT, stdout)
Cannot use both "--autostash" option and "--init" option.
STDOUT
    assert_equal([], Dir.children("."))
  end

  test("die if already .git directory is exist") do
    init_repository
    new_file_path = Pathname("new_file.txt")
    command = "git cococo --init append_file #{new_file_path} wrote."
    stdout, status = *Open3.capture2(command)
    assert_equal(1, status.exitstatus)
    expected_stdout_pattern = <<EOS
"\\." directory should be nonexistent or empty\\.
git cococo found following files:

  .*?
  d.*? \\.
  d.*? \\.\\.
  d.*? \\.git

Run without "--init" option:

  \\$ git cococo append_file #{Regexp.escape(new_file_path.basename.to_s)} wrote\\.
EOS
    # find invalid line.
    expected_stdout_pattern.each_line(chomp: true).with_index do |l, i|
      assert_match(Regexp.compile("^#{l}$"), stdout, "i=#{i + 1}")
    end
    # assert line order.
    assert_match(Regexp.compile("\\A#{expected_stdout_pattern}\\Z",
                                Regexp::MULTILINE),
                 stdout)
    assert_equal([".git"], Dir.children("."))
  end
end
