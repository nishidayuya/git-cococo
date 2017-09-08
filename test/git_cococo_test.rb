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

    new_file_path = @repository_path / "new_file.txt"
    command = "git cococo write_file #{new_file_path.basename} wrote."
    Dir.chdir(@repository_path) do
      run_command(command)
    end

    assert_equal("run: #{command}\n", @repository.head.target.message)
    assert_equal(2, @repository.head.log.length)
    assert_equal("wrote.\n", new_file_path.read)
  end

  def run_command(*command)
    if !system(*command)
      raise "failure: #{command.inspect}"
    end
  end
end
