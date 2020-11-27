# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    add_filter '/spec/'
    track_files 'lib/**/*.rb'
    minimum_coverage 98
  end
end
