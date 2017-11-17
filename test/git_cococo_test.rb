require "open3"
require "pathname"
require "tmpdir"

require "rugged"
require "test/unit"

top_src_path = Pathname(__dir__).parent
ENV["PATH"] = [
  top_src_path / "exe",
  top_src_path / "test/bin",
  *ENV["PATH"].split(File::PATH_SEPARATOR),
].map(&:to_s).join(File::PATH_SEPARATOR)

Rugged::Repository.class_eval do
  def git_add(path)
    index.add(path.to_s)
    Dir.chdir(workdir) do
    end
    commit_tree = index.write_tree(self)
    index.write
    return commit_tree
  end

  def git_commit(tree, **options)
    options[:parents] ||= empty? ? [] : [head.target]
    return Rugged::Commit.create(self,
                                 **{
                                   message: "commit.",
                                   tree: tree,
                                   update_ref: "HEAD",
                                 }.merge(options))
  end
end

class GitCococoTest < Test::Unit::TestCase
  setup do
    d = Dir.mktmpdir
    @repository_path = Pathname(d)
    init_repository
  end

  teardown do
    @repository_path.rmtree
  end

  test("commit new file after command run") do
    exist_file_path = @repository_path / "exist_file.txt"
    exist_file_path.write("wrote.\n")
    @repository.git_commit(@repository.git_add(exist_file_path.basename))
    assert_equal(1, @repository.head.log.length)
    assert_git_status([])

    new_file_path = @repository_path / "new_file.txt"
    command = "git cococo write_file #{new_file_path.basename} wrote."
    Dir.chdir(@repository_path) do
      run_command(command)
    end

    assert_git_status([])
    assert_equal("run: #{command}\n", @repository.head.target.message)
    assert_equal(2, @repository.head.log.length)
    assert_equal("wrote.\n", new_file_path.read)
  end

  test("commit exist file after command run") do
    exist_file_path = @repository_path / "exist_file.txt"
    exist_file_path.write("wrote.\n")
    @repository.git_commit(@repository.git_add(exist_file_path.basename))
    assert_equal(1, @repository.head.log.length)
    assert_git_status([])

    command = "git cococo write_file #{exist_file_path.basename} wrote."
    Dir.chdir(@repository_path) do
      run_command(command)
    end

    assert_git_status([])
    assert_equal("run: #{command}\n", @repository.head.target.message)
    assert_equal(2, @repository.head.log.length)
    assert_equal("wrote.\nwrote.\n", exist_file_path.read)
  end

  test("commit with escaped command commit message: quote case") do
    exist_file_path = @repository_path / "exist_file.txt"
    exist_file_path.write("wrote.\n")
    @repository.git_commit(@repository.git_add(exist_file_path.basename))
    assert_equal(1, @repository.head.log.length)
    assert_git_status([])

    content = " \"'$PATH  # \\ "
    command = [
      *%w"git cococo write_file",
      exist_file_path.basename.to_s,
      content,
    ]
    Dir.chdir(@repository_path) do
      run_command(*command)
    end

    assert_git_status([])
    expected_content = content.gsub("\'", "'\\\\''") # ' => '\''
    assert_equal("run: #{command[0 .. -2].join(" ")} '#{expected_content}'\n",
                 @repository.head.target.message)
    assert_equal(2, @repository.head.log.length)
    assert_equal("wrote.\n#{content}\n", exist_file_path.read)
  end

  test("commit with escaped command commit message: sh -c case") do
    exist_file_path = @repository_path / "exist_file.txt"
    exist_file_path.write("writed.\n")
    @repository.git_commit(@repository.git_add(exist_file_path.basename))
    assert_equal(1, @repository.head.log.length)
    assert_git_status([])

    command = [
      *%w"git cococo sh -c",
      "git ls-files -z | xargs -0 sed -i -e 's/writed/wrote/g'",
    ]
    Dir.chdir(@repository_path) do
      run_command(*command)
    end

    assert_git_status([])
    # TODO: last 2-quote characters are extra.
    assert_equal(<<EOS, @repository.head.target.message)
run: git cococo sh -c 'git ls-files -z | xargs -0 sed -i -e '\\''s/writed/wrote/g'\\'''
EOS
    assert_equal(2, @repository.head.log.length)
    assert_equal("wrote.\n", exist_file_path.read)
  end

  test("do nothing and exit 1 if uncommitted changes are exists") do
    exist_file_path = @repository_path / "exist_file.txt"
    exist_file_path.write("wrote.\n")
    @repository.git_commit(@repository.git_add(exist_file_path.basename))

    uncommitted_file_path = @repository_path / "uncommitted_file.txt"
    uncommitted_file_path.write("wrote.\n")

    assert_git_status([["uncommitted_file.txt", [:worktree_new]]])
    assert_equal(1, @repository.head.log.length)
    command = [
      *%w"git cococo sh -c",
      "git ls-files -z | xargs -0 sed -i -e 's/writed/wrote/g'",
    ]
    Dir.chdir(@repository_path) do
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
    end

    assert_git_status([["uncommitted_file.txt", [:worktree_new]]])
    assert_equal(1, @repository.head.log.length)
  end

  sub_test_case("--autostash") do
    test("stash, commit and unstash if uncommitted changes are exists") do
      exist_file_path = @repository_path / "exist_file.txt"
      exist_file_path.write("wrote.\n")
      @repository.git_commit(@repository.git_add(exist_file_path.basename))

      uncommitted_file_path = @repository_path / "uncommitted_file.txt"
      uncommitted_file_path.write("wrote.\n")

      assert_git_status([["uncommitted_file.txt", [:worktree_new]]])
      assert_equal(1, @repository.head.log.length)
      new_file_path = @repository_path / "new_file.txt"
      command = "git cococo --autostash write_file #{new_file_path.basename} wrote."
      Dir.chdir(@repository_path) do
        run_command(command)
      end

      assert_git_status([["uncommitted_file.txt", [:worktree_new]]])
      assert_equal(2, @repository.head.log.length)
      assert_equal("wrote.\n", new_file_path.read)
    end
  end

  sub_test_case("--init") do
    setup do
      (@repository_path / ".git").rmtree
      @repository = nil
    end

    test("run command, git init and commit in current directory") do
      new_file_path = @repository_path / "new_file.txt"
      command = "git cococo --init write_file #{new_file_path.basename} wrote."
      Dir.chdir(@repository_path) do
        run_command(command)
      end

      @repository = Rugged::Repository.new((@repository_path / ".git").to_s)
      assert_git_status([])
      assert_equal("run: #{command}\n", @repository.head.target.message)
      assert_equal(1, @repository.head.log.length)
      assert_equal("wrote.\n", new_file_path.read)
    end

    test("run command in current directory and git init and commit specified directory") do
      command = [
        *%w"git cococo --init=blog sh -c",
        "mkdir blog && write_file blog/2017-10-25-sunny.txt Today is sunny!",
      ]
      Dir.chdir(@repository_path) do
        run_command(*command)
      end

      repository_path = @repository_path / "blog"
      @repository = Rugged::Repository.new((repository_path / ".git").to_s)
      assert_git_status([])
      assert_equal("run: #{command[0 .. -2].join(" ")} '#{command[-1]}'\n",
                   @repository.head.target.message)
      assert_equal(1, @repository.head.log.length)
      assert_equal("Today is sunny!\n",
                   (repository_path / "2017-10-25-sunny.txt").read)
    end

    test("cannot use with --autostash option") do
      new_file_path = @repository_path / "new_file.txt"
      command = "git cococo --autostash --init write_file #{new_file_path.basename} wrote."
      Dir.chdir(@repository_path) do
        stdout, status = *Open3.capture2(command)
        assert_equal(1, status.exitstatus)
        assert_equal(<<STDOUT, stdout)
Cannot use both "--autostash" option and "--init" option.
STDOUT
      end

      assert_equal([], @repository_path.children)
    end

    test("die if already .git directory is exist") do
      init_repository
      new_file_path = @repository_path / "new_file.txt"
      command = "git cococo --init write_file #{new_file_path.basename} wrote."
      Dir.chdir(@repository_path) do
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

  \\$ git cococo write_file #{Regexp.escape(new_file_path.basename.to_s)} wrote\\.
EOS
        # find invalid line.
        expected_stdout_pattern.each_line(chomp: true).with_index do |l, i|
          assert_match(Regexp.compile("^#{l}$"), stdout, "i=#{i + 1}")
        end
        # assert line order.
        assert_match(Regexp.compile("\\A#{expected_stdout_pattern}\\Z",
                                    Regexp::MULTILINE),
                     stdout)
      end

      assert_equal([@repository_path / ".git"], @repository_path.children)
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
    @repository = Rugged::Repository.init_at(@repository_path.to_s)
  end

  def run_command(*command)
    if !system(*command)
      raise RunCommandError, "failure: #{command.inspect}"
    end
  end
end
