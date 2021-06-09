# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'app_status_notification'

require 'pry-byebug'
require 'awesome_print'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

task(default: %i[spec rubocop])
