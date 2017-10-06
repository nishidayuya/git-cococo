require "rake/testtask"

def run(*command)
  # This method will be removed at ruby-2.6.0.
  #
  # See: https://bugs.ruby-lang.org/issues/14386
  if !system(*command)
    raise "command execution failure: #{command.inspect}"
  end
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

task(:lint) do
  run("shellcheck exe/git-cococo")
end

task(default: :test)
