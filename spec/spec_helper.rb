$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift File.dirname(__FILE__)

require "bundler/setup"
require 'rspec'
require 'rdf'
require 'rdf/ntriples'
require 'rdf/turtle'
require 'rdf/spec'
require 'rdf/spec/matchers'
begin
  require 'simplecov'
  require 'simplecov-lcov'

  SimpleCov::Formatter::LcovFormatter.config do |config|
    #Coveralls is coverage by default/lcov. Send info results
    config.report_with_single_file = true
    config.single_report_path = 'coverage/lcov.info'
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError
end
require 'yarspg'

module RDF
  module Isomorphic
    alias_method :==, :isomorphic_with?
  end
end

::RSpec.configure do |c|
  c.filter_run focus:  true
  c.run_all_when_everything_filtered = true
  c.include(RDF::Spec::Matchers)
end
