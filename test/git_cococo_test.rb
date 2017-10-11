require "open3"
require "pathname"
require "tmpdir"

require "rugged"
require "test/unit"

top_src_path = Pathname(__dir__).parent
ENV["PATH"] = [
  top_src_path / "exe",
  top_src_path / "test/bin",
  *ENV["PATH"].split(":"),
].map(&:to_s).join(":")

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
    @repository = Rugged::Repository.init_at(d)
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

    content = " \"'$PATH  # \\"
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
    new_file_path = @repository_path / "new_file.txt"
    assert_equal(false, new_file_path.exist?)
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
    assert_equal(false, new_file_path.exist?)
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

  def run_command(*command)
    if !system(*command)
      raise RunCommandError, "failure: #{command.inspect}"
    end
  end
end
