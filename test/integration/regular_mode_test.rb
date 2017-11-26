require "test_helper"

class RegularModeTest < Test::Unit::TestCase
  setup do
    @original_current_path = Pathname(Dir.pwd)
    @working_path = Pathname(Dir.mktmpdir)
    Dir.chdir(@working_path)
    init_repository
  end

  teardown do
    Dir.chdir(@original_current_path)
    @working_path.rmtree
  end

  test("commit new file after command run") do
    prepare_committed_file
    assert_equal(1, @repository.head.log.length)
    assert_git_status([])

    new_file_path = Pathname("new_file.txt")
    command = "git cococo append_file #{new_file_path} wrote."
    run_command(command)

    assert_git_status([])
    assert_equal("run: #{command}\n", @repository.head.target.message)
    assert_equal(2, @repository.head.log.length)
    assert_equal("wrote.\n", new_file_path.read)
  end

  test("commit exist file after command run") do
    prepare_committed_file
    assert_equal(1, @repository.head.log.length)
    assert_git_status([])

    command = "git cococo append_file #{@exist_file_path} wrote."
    run_command(command)

    assert_git_status([])
    assert_equal("run: #{command}\n", @repository.head.target.message)
    assert_equal(2, @repository.head.log.length)
    assert_equal("wrote.\nwrote.\n", @exist_file_path.read)
  end

  test("commit with escaped command commit message: quote case") do
    prepare_committed_file
    assert_equal(1, @repository.head.log.length)
    assert_git_status([])

    content = " \"'$PATH  # \\ "
    command = [
      *%w"git cococo append_file",
      @exist_file_path.to_s,
      content,
    ]
    run_command(*command)

    assert_git_status([])
    expected_content = content.gsub("\'", "'\\\\''") # ' => '\''
    assert_equal("run: #{command[0 .. -2].join(" ")} '#{expected_content}'\n",
                 @repository.head.target.message)
    assert_equal(2, @repository.head.log.length)
    assert_equal("wrote.\n#{content}\n", @exist_file_path.read)
  end

  test("commit with escaped command commit message: sh -c case") do
    prepare_committed_file(content: "writed.\n")
    assert_equal(1, @repository.head.log.length)
    assert_git_status([])

    command = [
      *%w"git cococo sh -c",
      "git ls-files -z | xargs -0 sed -i -e 's/writed/wrote/g'",
    ]
    run_command(*command)

    assert_git_status([])
    # TODO: last 2-quote characters are extra.
    assert_equal(<<EOS, @repository.head.target.message)
run: git cococo sh -c 'git ls-files -z | xargs -0 sed -i -e '\\''s/writed/wrote/g'\\'''
EOS
    assert_equal(2, @repository.head.log.length)
    assert_equal("wrote.\n", @exist_file_path.read)
  end

  test("do nothing and exit 1 if uncommitted changes are exists") do
    prepare_committed_file

    uncommitted_file_path = Pathname("uncommitted_file.txt")
    uncommitted_file_path.write("wrote.\n")

    assert_git_status([["uncommitted_file.txt", [:worktree_new]]])
    assert_equal(1, @repository.head.log.length)
    command = [
      *%w"git cococo sh -c",
      "git ls-files -z | xargs -0 sed -i -e 's/writed/wrote/g'",
    ]
    stdout, status = *Open3.capture2(*command)
    assert_equal(1, status.exitstatus)
    assert_equal(<<STDOUT, stdout)
Detects following uncommitted changes:

  ?? uncommitted_file.txt

Run "git stash" and retry "git cococo":

  $ git stash --include-untracked &&
    git cococo sh -c 'git ls-files -z | xargs -0 sed -i -e '\\''s/writed/wrote/g'\\''' &&
    git stash pop

Or, use "--autostash" option:

  $ git cococo --autostash sh -c 'git ls-files -z | xargs -0 sed -i -e '\\''s/writed/wrote/g'\\'''
STDOUT

    assert_git_status([["uncommitted_file.txt", [:worktree_new]]])
    assert_equal(1, @repository.head.log.length)
  end

  sub_test_case("--autostash") do
    test("stash, commit and unstash if uncommitted changes are exists") do
      prepare_committed_file

      uncommitted_file_path = Pathname("uncommitted_file.txt")
      uncommitted_file_path.write("wrote.\n")

      assert_git_status([["uncommitted_file.txt", [:worktree_new]]])
      assert_equal(1, @repository.head.log.length)
      new_file_path = Pathname("new_file.txt")
      command = "git cococo --autostash append_file #{new_file_path} wrote."
      run_command(command)

      assert_git_status([["uncommitted_file.txt", [:worktree_new]]])
      assert_equal(2, @repository.head.log.length)
      assert_equal("wrote.\n", new_file_path.read)
    end
  end

  private

  class RunCommandError < StandardError
  end

  def assert_git_status(expected)
    actual = []
    @repository.status do |*args|
      actual << args
    end
    assert_equal(expected, actual)
  end

  def init_repository
    @repository = Rugged::Repository.init_at(".")
  end

  def run_command(*command)
    if !system(*command)
      raise RunCommandError, "failure: #{command.inspect}"
    end
  end

  def prepare_committed_file(path: "exist_file.txt", content: "wrote.\n")
    @exist_file_path = Pathname(path)
    @exist_file_path.parent.mkpath
    @exist_file_path.write(content)
    @repository.git_commit(@repository.git_add(@exist_file_path))
  end
end
