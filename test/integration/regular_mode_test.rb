require "test_helper"

class RegularModeTest < IntegrationTestCase
  setup(:prepare_working_path)
  setup(:init_repository)
  teardown(:destroy_working_path)

  test("commit new file after command run") do
    prepare_committed_file
    assert_equal(1, @repository.log.size)
    assert_untracked_files([])

    new_file_path = Pathname("new_file.txt")
    command = "git cococo append_file #{new_file_path} wrote."
    run_command(command)

    assert_untracked_files([])
    assert_equal("run: #{command}", @repository.log.first.message)
    assert_equal(2, @repository.log.size)
    assert_equal("wrote.\n", new_file_path.read)
  end

  test("commit exist file after command run") do
    prepare_committed_file
    assert_equal(1, @repository.log.size)
    assert_untracked_files([])

    command = "git cococo append_file #{@exist_file_path} wrote."
    run_command(command)

    assert_untracked_files([])
    assert_equal("run: #{command}", @repository.log.first.message)
    assert_equal(2, @repository.log.size)
    assert_equal("wrote.\nwrote.\n", @exist_file_path.read)
  end

  test("commit with escaped command commit message: quote case") do
    prepare_committed_file
    assert_equal(1, @repository.log.size)
    assert_untracked_files([])

    content = " \"'$PATH  # \\ "
    command = [
      *%w"git cococo append_file",
      @exist_file_path.to_s,
      content,
    ]
    run_command(*command)

    assert_untracked_files([])
    expected_content = content.gsub("\'", "'\\\\''") # ' => '\''
    assert_equal("run: #{command[0 .. -2].join(" ")} '#{expected_content}'",
                 @repository.log.first.message)
    assert_equal(2, @repository.log.size)
    assert_equal("wrote.\n#{content}\n", @exist_file_path.read)
  end

  test("commit with escaped command commit message: sh -c case") do
    prepare_committed_file(content: "writed.\n")
    assert_equal(1, @repository.log.size)
    assert_untracked_files([])

    command = [
      *%w"git cococo sh -c",
      "git ls-files -z | xargs -0 sed -i -e 's/writed/wrote/g'",
    ]
    run_command(*command)

    assert_untracked_files([])
    # TODO: last 2-quote characters are extra.
    assert_equal(<<EOS.chomp, @repository.log.first.message)
run: git cococo sh -c 'git ls-files -z | xargs -0 sed -i -e '\\''s/writed/wrote/g'\\'''
EOS
    assert_equal(2, @repository.log.size)
    assert_equal("wrote.\n", @exist_file_path.read)
  end

  test("commit with backslash in command argument") do
    prepare_committed_file
    assert_equal(1, @repository.log.size)
    assert_untracked_files([])

    command = %W"git cococo append_file #{@exist_file_path} \\a\\b\a\b\\n"
    run_command(*command)
    assert_equal(<<EOS, @exist_file_path.read)
wrote.
\\a\\b\a\b\\n
EOS

    assert_untracked_files([])
    assert_equal(<<EOS.chomp, @repository.log.first.message)
run: git cococo append_file #{@exist_file_path} '\\a\\b\a\b\\n'
EOS
    assert_equal(2, @repository.log.size)
    assert_equal(<<EOS, @exist_file_path.read)
wrote.
\\a\\b\a\b\\n
EOS
  end

  test("do nothing and exit 1 if uncommitted changes are exists") do
    prepare_committed_file

    uncommitted_file_path = Pathname("uncommitted_file.txt")
    uncommitted_file_path.write("wrote.\n")

    assert_untracked_files([uncommitted_file_path])
    assert_equal(1, @repository.log.size)
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
    assert_untracked_files([uncommitted_file_path])
    assert_equal(1, @repository.log.size)
  end

  sub_test_case("--autostash") do
    test("stash, commit and unstash if uncommitted changes are exists") do
      prepare_committed_file

      uncommitted_file_path = Pathname("uncommitted_file.txt")
      uncommitted_file_path.write("wrote.\n")

      assert_untracked_files([uncommitted_file_path])
      assert_equal(1, @repository.log.size)
      new_file_path = Pathname("new_file.txt")
      command = "git cococo --autostash append_file #{new_file_path} wrote."
      run_command(command)

      assert_untracked_files([uncommitted_file_path])
      assert_equal(2, @repository.log.size)
      assert_equal("wrote.\n", new_file_path.read)
    end
  end

  private

  def prepare_committed_file(path: "exist_file.txt", content: "wrote.\n")
    @exist_file_path = Pathname(path)
    @exist_file_path.parent.mkpath
    @exist_file_path.write(content)
    @repository.add(@exist_file_path.to_s)
    @repository.commit("commit.")
  end
end
