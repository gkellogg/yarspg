require 'rdf'

##
# **`YARSPG`** is an YARS-PG extension for RDF.rb.
#
# @example Requiring the `YARSPG` module
#   require 'yarspg'
#
# @example Parsing statements from a YARS-PG file into a graph using RDF*.
#   YARSPG::Reader.open("etc/foaf.yarspg") do |reader|
#     reader.each_statement do |statement|
#       puts statement.inspect
#     end
#   end
#
# @see https://ruby-rdf.github.io/rdf/
# @see https://lszeremeta.github.io/yarspg/index.html
#
# @author [Gregg Kellogg](https://greggkellogg.net/)
module YARSPG
  require  'yarspg/format'
  autoload :Reader,         'yarspg/reader'
  autoload :VERSION,        'yarspg/version'
  autoload :Writer,         'yarspg/writer'
end
