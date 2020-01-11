require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

task(:lint) do
  system("shellcheck exe/git-cococo", exception: true)
end

task(default: %i[test lint])
