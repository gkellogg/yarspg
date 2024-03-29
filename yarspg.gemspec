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
  gem.files              = %w(README.md UNLICENSE VERSION) + Dir.glob('lib/**/*.rb')
  gem.require_paths      = %w(lib)
  gem.description        = %(YARSPG is an YARS-PG reader/writer for the RDF.rb library suite.)
  gem.metadata           = {
    "documentation_uri" => "https://gkellogg.github.io/yarspg",
    "bug_tracker_uri"   => "https://github.com/gkellogg/yarspg/issues",
    "homepage_uri"      => "https://github.com/gkellogg/yarspg",
    "source_code_uri"   => "https://github.com/gkellogg/yarspg",
  }

  gem.required_ruby_version      = '>= 2.6'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',                   '~> 3.2'
  gem.add_runtime_dependency     'ebnf',                  '~> 2.2'
  gem.add_runtime_dependency     'json-canonicalization', '~> 0.3'
  gem.add_runtime_dependency     'sxp',                   '~> 1.2'
  gem.add_runtime_dependency     'rdf-xsd',               '~> 3.2'

  gem.add_development_dependency 'rdf-spec',              '~> 3.2'
  gem.add_development_dependency 'rspec',                 '~> 3.10'
  gem.add_development_dependency 'rspec-its',             '~> 1.3'
  gem.add_development_dependency 'yard' ,                 '~> 0.9'

  gem.post_install_message       = nil
end