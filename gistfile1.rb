#!/usr/bin/env ruby
#
# A hook script to verify that only syntactically valid ruby code is commited.
# Called by git-commit with no arguments.  The hook should
# exit with non-zero status after issuing an appropriate message if
# it wants to stop the commit.
#
# Put this code into a file called "pre-commit" inside your .git/hooks
# directory, and make sure it is executable ("chmod +x .git/hooks/pre-commit")
#
# Tested only with Git 1.6.4-rc1, but should work with any Git 1.6

require 'open3'
include Open3

changed_ruby_files = `git diff-index --name-only --cached HEAD`.inject([]) do |files, line|
  files << line.chomp if line =~ /(.+\.(e?rb|task)|Rakefile)/
  files
end

problematic_files = changed_ruby_files.inject([]) do |problematic_files, file|
  cmd = if file =~ /\.erb\z/
    # Set trim mode to "-", just as Rails does
    "erb -xT - #{file} | ruby -c"
  else
    "ruby -c #{file}"
  end

  errors = nil
  popen3(cmd) do |stdin, stdout, stderr|
    errors = stderr.read.split("\n")
  end

  unless errors.empty?
    errors.map!{ |line| line.sub(/#{file}:/, '') }
    problematic_files << "#{file}:\n#{errors.join("\n")}"
  end

  problematic_files
end

if problematic_files.size > 0
  $stderr.puts problematic_files.join("\n\n")
  exit 1
else
  # All is well
  exit 0
end
