require "open3"
require "pathname"
require "tmpdir"

require "rugged"
require "test/unit"

TOP_SRC_PATH = Pathname(__dir__).parent
EXE_PATH = TOP_SRC_PATH / "exe"

ENV["PATH"] = [
  EXE_PATH,
  TOP_SRC_PATH / "test/bin",
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

class RunCommandError < StandardError
end

class GitCococoTestCase < Test::Unit::TestCase
end

class UnitTestCase < GitCococoTestCase
end

class IntegrationTestCase < GitCococoTestCase
  private

  def prepare_working_path
    @original_current_path = Pathname(Dir.pwd)
    @working_path = Pathname(Dir.mktmpdir)
    Dir.chdir(@working_path)
  end

  def destroy_working_path
    Dir.chdir(@original_current_path)
    @working_path.rmtree
  end

  def init_repository
    @repository = Rugged::Repository.init_at(".")
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
