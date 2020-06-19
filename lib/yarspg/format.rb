module YARSPG
  ##
  # YARS-PG format specification.
  #
  # @example Obtaining an ## format class
  #     RDF::Format.for("etc/foaf.yarspg")
  #     RDF::Format.for(file_name:      "etc/foaf.yarspg")
  #     RDF::Format.for(file_extension: "yarspg")
  #     RDF::Format.for(content_type:   "text/yarspg")
  #
  # @example Obtaining serialization format MIME types
  #     RDF::Format.content_types      #=> {"text/yarspg" => [YARSPG::Format]}
  #
  # @example Obtaining serialization format file extension mappings
  #     RDF::Format.file_extensions    #=> {yarspg: "text/yarspg"}
  #
  # @see https://www.w3.org/TR/rdf-testcases/#ntriples
  class Format < RDF::Format
    content_type     'text/yarspg',
                     extension: :yarspg
    content_encoding 'utf-8'

    reader { YARSPG::Reader }
    writer { YARSPG::Writer }

    ##
    # Sample detection to see if it matches YARS-PG
    #
    # Use a text sample to detect the format of an input file. Sub-classes implement a matcher sufficient to detect probably format matches, including disambiguating between other similar formats.
    #
    # @param [String] sample Beginning several bytes (~ 1K) of input.
    # @return [Boolean]
    def self.detect(sample)
      !!sample.match(%r(
        (?:%(METADATA|NODE SCHEMAS|EDGE SCHEMAS|NODES|EDGES)) | # Section Names
        (?:[S\{.*\}]-)                                        | # Node Schema
        (?:[S\(.*\)]-)                                        | # Edge Schema
        (?:\(.*\)-)                                             # Edge
      )mx)
    end
  end
end
