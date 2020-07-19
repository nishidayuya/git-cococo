#!/usr/bin/env ruby

# HELP! pull-requests are welcome!!
# On Windows, `bundle exec rake test` occurs SIGSEGV after all tests are success.
# This file is ad-hoc hack for test on Windows.

require "pathname"

test_path = Pathname(__dir__).expand_path
lib_path = (test_path.parent / "lib").expand_path
$LOAD_PATH << lib_path
$LOAD_PATH << test_path

Pathname.glob(test_path / "**/*_test.rb").sort.each do |path|
  name = path.sub_ext("").relative_path_from(test_path)
  require name.to_s
end
