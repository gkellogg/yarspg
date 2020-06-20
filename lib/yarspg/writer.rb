module YARSPG
  ##
  # A YARS-PG serialiser
  #
  # @author [Gregg Kellogg](https://greggkellogg.net/)
  class Writer < RDF::Writer
    include RDF::Util::Logger
    format YARSPG::Format
  end
end
