#!/usr/bin/env ruby
$:.unshift(File.expand_path("../lib", __FILE__))
require 'rubygems'

namespace :gem do
  desc "Build the yarspg-#{File.read('VERSION').chomp}.gem file"
  task :build do
    sh "gem build yarspg.gemspec && mv yarspg-#{File.read('VERSION').chomp}.gem pkg/"
  end

  desc "Release the yarspg-#{File.read('VERSION').chomp}.gem file"
  task :release do
    sh "gem push pkg/yarspg-#{File.read('VERSION').chomp}.gem"
  end
end

desc 'Create versions of ebnf files in etc'
task etc: %w{etc/yars-pg.sxp etc/yars-pg.peg.sxp etc/yars-pg.html}

desc 'Build rules table'
task meta: "lib/yarspg/meta.rb"

file "lib/yarspg/meta.rb" => "etc/yars-pg.ebnf" do |t|
  sh %{
    ebnf --peg --format rb \
      --mod-name YARSPG::Meta \
      --output lib/yarspg/meta.rb \
      etc/yars-pg.ebnf
  }
end

file "etc/yars-pg.peg.sxp" => "etc/yars-pg.ebnf" do |t|
  sh %{
    ebnf --peg --format sxp \
      --output etc/yars-pg.peg.sxp \
      etc/yars-pg.ebnf
  }
end

file "etc/yars-pg.sxp" => "etc/yars-pg.ebnf" do |t|
  sh %{
    ebnf --format sxp \
      --output etc/yars-pg.sxp \
      etc/yars-pg.ebnf
  }
end

file "etc/yars-pg-bnf.sxp" => "etc/yars-pg.ebnf" do |t|
  sh %{
    ebnf --bnf --format sxp \
      --output etc/yars-pg-bnf.sxp \
      etc/yars-pg.ebnf
  }
end

file "etc/yars-pg.html" => "etc/yars-pg.ebnf" do |t|
  sh %{
    ebnf --format html \
      --output etc/yars-pg.html \
      etc/yars-pg.ebnf
  }
end
