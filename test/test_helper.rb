require "open3"
require "pathname"
require "shellwords"
require "tmpdir"

require "git"
require "test/unit"

TOP_SRC_PATH = Pathname(__dir__).parent
EXE_PATH = TOP_SRC_PATH / "exe"

ENV["PATH"] = [
  EXE_PATH,
  TOP_SRC_PATH / "test/bin",
  *ENV["PATH"].split(File::PATH_SEPARATOR),
].map(&:to_s).join(File::PATH_SEPARATOR)

Git::Base.class_eval do
  def git_add(path)
    add(path)
  end

  def git_commit(tree, **options)
    message = options[:message] || "commit."
    commit(message)
  end
end

class RunCommandError < StandardError
end

class GitCococoTestCase < Test::Unit::TestCase
end

class UnitTestCase < GitCococoTestCase
  private

  COMMAND_PATH = EXE_PATH / "git-cococo"

  def test_method_name
    return self.class.name[/(?<=::).*\z/]
  end
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
    @repository = Git.init(".")
  end

  def assert_untracked_files(expected_path_ary)
    expected_path_ary = expected_path_ary.map(&:to_s)
    assert_equal(expected_path_ary, @repository.status.untracked.keys.sort)

    # We must write sorted expected paths.
    assert_equal(expected_path_ary.sort.uniq, expected_path_ary)
  end

  def run_command(*command)
    if !system(*command)
      raise RunCommandError, "failure: #{command.inspect}"
    end
  end
end
