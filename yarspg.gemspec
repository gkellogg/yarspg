#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = "yarspg"
  gem.homepage           = "https://github.com/gkellogg/yarspg"
  gem.license            = 'Unlicense'
  gem.summary            = "YARS-PG reader/writer for RDF.rb."
  gem.authors            = ['Gregg Kellogg']
  gem.email              = 'gregg@greggkellogg.net'
  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(README.md UNLICENSE VERSION bin/yarspg) + Dir.glob('lib/**/*.rb')
  gem.require_paths      = %w(lib)
  gem.description        = %(YARSPG is an YARS-PG reader/writer for the RDF.rb library suite.)

  gem.required_ruby_version      = '>= 2.4'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',                   '~> 3.1'
  gem.add_runtime_dependency     'ebnf',                  '~> 2.0'
  gem.add_runtime_dependency     'json-canonicalization', '~> 0.2'
  gem.add_runtime_dependency     'sxp',                   '~> 1.1'
  gem.add_runtime_dependency     'rdf-xsd',               '~> 3.1'

  gem.add_development_dependency 'rdf-spec',              '~> 3.1'
  gem.add_development_dependency 'rspec',                 '~> 3.9'
  gem.add_development_dependency 'rspec-its',             '~> 1.3'
  gem.add_development_dependency 'yard' ,                 '~> 0.9.20'

  gem.post_install_message       = nil
end