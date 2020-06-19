# coding: utf-8
require 'ebnf'
require 'yarspg/meta'
require 'yarspg/terminals'
require 'json/canonicalization'

module YARSPG
  ##
  # A parser for YARS-PG.
  #
  # Parses into RDF*, taking liberties with the meaning of a Property Graph.
  #
  # Issues:
  #   * Is it an error to parse data outside of a declared section? (warning?)
  #   * Node lables are treated like types
  #   * Node properties are treated like statements on that node
  #   * Node string annotations are treated like statements with the predicate created as a document fragment.
  #

  class Reader < RDF::Reader
    format Format
    include EBNF::PEG::Parser
    include YARSPG::Meta
    include YARSPG::Terminals
    include RDF::Util::Logger

    SECTION_ORDERS = {
      METADATA:       0,
      "NODE SCHEMAS": 1,
      "EDGE SCHEMAS": 2,
      NODES:          3,
      EDGES:          4
    }

    # Terminial definitions

    # Always return a literal, to distinguish between actual string terminals.
    terminal(:STRING,        STRING) {|value| RDF::Literal(value[1..-2])}
    terminal(:NUMBER,        NUMBER) do |value|
      value.include?('.') ?
        RDF::Literal::Decimal.new(value) :
        RDF::Literal::Integer.new(value)
    end

    terminal(:BOOL,          BOOL) {|value| RDF::Literal::Boolean.new(value)}
    terminal(:ALNUM_PLUS,    ALNUM_PLUS)
    terminal(:IRI,           IRI) { |value| RDF::URI(value[1..-2])}
    terminal(:DATE,          DATE) {|value| RDF::Literal::Date.new(value)}
    terminal(:TIME,          TIME) {|value| RDF::Literal::Time.new(value)}
    terminal(:TIMESTAMP,     TIMESTAMP) {|value| RDF::Literal::DateTime.new(value)}

    # `[3]   prefix_directive  ::= pname IRI`
    production(:prefix_directive) do |value|
      pfx = value.first[:pname].to_sym
      prefixes[pfx] = value.last[:IRI]
    end

    # `[4]   pname ::= ":" ALNUM_PLUS ":"`
    production(:pname) {|value| value[1][:ALNUM_PLUS]}

    # `[5]   pn_local  ::= ALNUM_PLUS`
    #
    # This must be a prefix
    production(:pn_local) do |value|
      pfx = value.first[:ALNUM_PLUS].to_sym
      error("pn_local", "no prefix defined for #{pfx}") unless prefixes[pfx]
      prefixes[pfx]
    end

    # `[6]   metadata  ::= "-" ((pn_local pname) | (IRI ":")) (STRING | IRI)`
    production(:metadata) do |value, data, callback|
      pred = value[1][:_metadata_1]
      obj = value[2][:_metadata_2]
      callback.call(:statement, :metadata, base_uri, pred, obj)
      nil
    end
    # `(seq pn_local pname)`
    production(:_metadata_3) {|value| value.first[:pn_local].join(value.last[:pname])}
    # `(seq IRI ":")`
    production(:_metadata_4) {|value| value.first[:IRI]}

    # `[6a]  graph_name ::= STRING`
    production(:graph_name) {|value| base_uri.join("##{value.first[:STRING]}")}

    production(:annotation) {|value| value}

    # `[8]   string_annotation ::= STRING ":" STRING`
    #
    # Treated as an RDF annotation where the string is interpreted as a predicate based on the base_uri.
    production(:string_annotation) do |value|
      pred = base_uri.join("##{value.first[:STRING]}")
      obj = value.last[:STRING]
      RDF::Statement(nil, pred, obj)
    end

    # `[9]   rdf_annotation  ::= ((pn_local pname) | (IRI ":")) (STRING | IRI)`
    #
    # Returns a statement without subject
    production(:rdf_annotation) do |value|
      pred = value.first[:_rdf_annotation_1]
      obj = value.last[:_rdf_annotation_2]
      RDF::Statement(nil, pred, obj)
    end
    # `(seq pn_local pname)`
    production(:_rdf_annotation_3) {|value| value.first[:pn_local].join(value.last[:pname])}
    # `(seq IRI ":")`
    production(:_rdf_annotation_4) {|value| value.first[:IRI]}

    # `[10]  annotations_list  ::= "+" annotation ("," annotation)*`
    production(:annotations_list) do |value|
      value.last[:_annotations_list_1].unshift(value[1][:annotation])
    end
    # `(star _annotations_list_2)`
    production(:_annotations_list_1) {|value| value.map {|al| al[1][:annotation]}}

    # `[11]  props_list  ::= "[" prop ("," prop)* "]"`
    production(:props_list) do |value|
      value[2][:_props_list_1].unshift(value[1][:prop])
    end
    # `(star _props_list_2)`
    production(:_props_list_1) {|value| value.map {|prop| prop[1][:prop]}}

    # `[12]  graphs_list ::= "/" graph_name ("," graph_name)* "/"`
    production(:graphs_list) do |value|
      value[2][:_graphs_list_1].unshift(value[1][:graph_name])
    end
    # `seq "," graph_name)`
    production(:_graphs_list_2) {|value| value.last[:graph_name]}

    # `[13]  node  ::= "<" node_id ">" ("{" node_label ("," node_label)* "}")? props_list? graphs_list? annotations_list?
    production(:node) do |value, data, callback|
      subject = value[1][:node_id]
      types = Array(value[3][:_node_1])
      props = Array(value[4][:_node_2])
      graphs = Array(value[5][:_node_3])
      annotations = Array(value[6][:_node_4])

      # Yield statements
      types.each do |type|
        callback.call(:statement, :node, subject, RDF.type, type)
      end
      props.each do |statement|
        callback.call(:statement, :node, subject, statement.predicate, statement.object)
      end
      annotations.each do |statement|
        callback.call(:statement, :node, subject, statement.predicate, statement.object)
      end

      nil
    end
    # `(seq "{" node_label _node_6 "}")`
    production(:_node_5) do |value|
      value[2][:_node_6].unshift(value[1][:node_label])
    end
    # `(seq "," node_label)`
    production(:_node_7) {|value| value.last[:node_label]}

    production(:edge) {|value| value}

    # `[15]  section ::= "%" SECTION_NAME`
    production(:section) do |value|
      # Note the section we're parsing; this can generate a warning if parsing something outside the section (other than the next section), or if seeing past the last section
      section = value.last[:SECTION_NAME].to_sym
      if !@in_section.nil? && @in_section > SECTION_ORDERS[section.to_sym]
        warn("section", "parsing section #{section} out of order.")
      end
      @in_section = SECTION_ORDERS[section.to_sym]
      {section: section.to_sym}
    end

    production(:directed) {|value| value}
    production(:undirected) {|value| value}

    # `[18]  node_id ::= STRING`
    production(:node_id) {|value| base_uri.join("##{value.first[:STRING]}")}

    # `[19]  node_label  ::= STRING`
    production(:node_label) {|value| base_uri.join("##{value.first[:STRING]}")}

    # `[20]  prop  ::= key ":" value
    #
    # Treated as an String annotation.
    production(:prop) do |value|
      pred = base_uri.join("##{value.first[:key]}")
      obj = RDF::Literal(value.last[:value])
      RDF::Statement(nil, pred, obj)
    end

    production(:edge_id) {|value| value}
    production(:edge_label) {|value| value}
    production(:key) {|value| value.first[:STRING].to_s}
    production(:value) {|value| value}

    # `[25]  primitive_value ::= STRING | DATETYPE | NUMBER | BOOL | "null"`
    production(:primitive_value) {|value| value == "null" ? RDF.nil : value}

    # `[26]  complex_value ::= set | list | struct`
    #
    # At the start, record that we're from a complex value, so proper RDF values are created only after recursive calls are complete.
    start_production(:complex_value) {|data| data[:from_complex_value] = true}
    production(:complex_value) {|value| value}

    # 27]  set ::= "{" (primitive_value | set) ("," (primitive_value | set))* "}"
    #
    # Because this is recursive, we'll only return a JSON literal if called from complex_value
    production(:set) do |value|
      set = value[2][:_set_2].unshift(value[1][:_set_1])
      if prod_data[:from_complex_value]
        # Wrap value in a literal
        RDF::Literal(set.to_json_c14n, datatype: RDF.JSON)
      else
        set
      end
    end
    # `(alt primitive_value struct)`
    production(:_set_1) {|value| value.is_a?(RDF::Literal) ? value.to_s : value}
    # `(seq "," _set_4)`
    production(:_set_3) {|value| value.last[:_set_4]}
    # `(alt primitive_value struct)`
    production(:_set_4) {|value| value.is_a?(RDF::Literal) ? value.to_s : value}

    # `[28]  list  ::= "[" (primitive_value | list) ("," (primitive_value | list))* "]"`
    production(:list) do |value|
      RDF::List(value[2][:_list_2].unshift(value[1][:_list_1]))
    end
    # (star _list_3)
    production(:_list_2) do |value|
      value.map {|li| li.last[:_list_4]}
    end

    # `[29]  struct  ::= "{" key ":" (primitive_value | struct) ("," key ":" (primitive_value | struct))* "}"`
    #
    # Because this is recursive, we'll only return a JSON literal if called from complex_value
    production(:struct) do |value|
      struct = {value[1][:key] => value[3][:_struct_1]}.merge(value[4][:_struct_2])
      if prod_data[:from_complex_value]
        # Wrap value in a literal
        RDF::Literal(struct.to_json_c14n, datatype: RDF.JSON)
      else
        struct
      end
    end
    # `(alt primitive_value struct)`
    production(:_struct_1) {|value| value.is_a?(RDF::Literal) ? value.to_s : value}
    # `(star _struct_3)`
    production(:_struct_2) do |value|
      value.inject({}) {|memo, struct| memo.merge(struct)}
    end
    # `(seq "," key ":" _struct_4)`
    production(:_struct_3) {|value| {value[1][:key] => value[3][:_struct_4]}}
    # `(alt primitive_value struct)`
    production(:_struct_4) {|value| value.is_a?(RDF::Literal) ? value.to_s : value}

    production(:node_schema) {|value| value}
    production(:props_list_schema) {|value| value}
    production(:prop_schema) {|value| value}
    production(:value_schema) {|value| value}
    production(:primitive_value_schema) {|value| value}
    production(:complex_value_schema) {|value| value}
    production(:set_schema) {|value| value}
    production(:list_schema) {|value| value}
    production(:struct_schema) {|value| value}
    production(:edge_schema) {|value| value}
    production(:directed_schema) {|value| value}
    production(:undirected_schema) {|value| value}

    ##
    # Initializes a new reader instance.
    #
    # This assumes that strings are interpreted as document-relative fragments.
    #
    # @param  [String, #to_s]          input
    # @param  [Hash{Symbol => Object}] options
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (for acessing intermediate parser productions)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (for acessing intermediate parser productions)
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values. If not validating,
    #   the parser will attempt to recover from errors.
    # @option options [Logger, #write, #<<] :logger
    #   Record error/info/debug output
    # @return [YARSPG::Reader]
    def initialize(input = nil, **options, &block)
      super do
        @options[:base_uri] = RDF::URI(base_uri || "")
        log_debug("base IRI") {base_uri.inspect}

        if block_given?
          case block.arity
            when 0 then instance_eval(&block)
            else block.call(self)
          end
        end
      end
    end

    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, base_uri.to_s)
    end

    ##
    # Iterates the given block for each RDF statement in the input.
    #
    # @yield  [statement]
    # @yieldparam [RDF::Statement] statement
    # @return [void]
    def each_statement(&block)
      if block_given?
        log_recover
        @callback = block

        parse(@input, :yarspg, YARSPG::Meta::RULES, **@options) do |context, *data|
          case context
          when :statement
            loc = data.shift
            s = RDF::Statement.from(data, lineno:  lineno)
            add_statement(loc, s) unless !s.valid? && validate?
          end
        end

        if validate? && log_statistics[:error]
          raise RDF::ReaderError, "Errors found during processing"
        end
      end
      enum_for(:each_statement)
    end
    
    ##
    # Iterates the given block for each RDF triple in the input.
    #
    # @yield  [subject, predicate, object]
    # @yieldparam [RDF::Resource] subject
    # @yieldparam [RDF::URI]      predicate
    # @yieldparam [RDF::Value]    object
    # @return [void]
    def each_triple(&block)
      if block_given?
        each_statement do |statement|
          block.call(*statement.to_triple)
        end
      end
      enum_for(:each_triple)
    end

    # add a statement, object can be literal or URI or bnode
    #
    # @param [Symbol] production
    # @param [RDF::Statement] statement the subject of the statement
    # @return [RDF::Statement] Added statement
    # @raise [RDF::ReaderError] Checks parameter types and raises if they are incorrect if parsing mode is _validate_.
    def add_statement(production, statement)
      error("Statement is invalid: #{statement.inspect.inspect}", production: produciton) if validate? && statement.invalid?
      @callback.call(statement) if statement.subject &&
                                   statement.predicate &&
                                   statement.object &&
                                   (validate? ? statement.valid? : true)
    end

  end
end