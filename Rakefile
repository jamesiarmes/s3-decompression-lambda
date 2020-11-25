# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: %i[spec rubocop]

desc 'Run RuboCop against the source code.'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options << '--display-cop-names'
  task.options << '--display-style-guide'
end

RSpec::Core::RakeTask.new(:spec) do
  ENV['COVERAGE'] = '1'
end
