#!/usr/bin/env rake
require "bundler"
require "bundler/gem_helper"
require "rake/testtask"
require "chefstyle"
require "rubocop/rake_task"

Bundler::GemHelper.install_tasks name: "train-salt"

#------------------------------------------------------------------#
#                    Code Style Tasks
#------------------------------------------------------------------#
RuboCop::RakeTask.new(:lint) do |task|
  task.options << "--display-cop-names"
  task.options << "-d"
end

#------------------------------------------------------------------#
#                    Test Runner Tasks
#------------------------------------------------------------------#

# This task template will make a task named 'test', and run
# the tests that it finds.

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList[
    "test/unit/*_test.rb",
    "test/functional/*_test.rb",
  ]
  t.verbose = true
  # Ideally, we'd run tests with warnings enabled,
  # but the dependent gems have many warnings. As this
  # is an example, let's disable them so the testing
  # experience is cleaner.
  t.warning = false
end

