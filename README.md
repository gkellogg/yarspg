# YARS-PG Property Graph to RDF* Processor.

[YARS-PG][] reader for [RDF.rb][]. Reads [Property Graph][] descriptions and generates [RDF*][] datasets.

[![Gem Version](https://badge.fury.io/rb/yarspg.png)](https://badge.fury.io/rb/yarspg)
[![Build Status](https://secure.travis-ci.org/gkellogg/yarspg.png?branch=master)](https://travis-ci.org/gkellogg/yarspg)
[![Coverage Status](https://coveralls.io/repos/gkellogg/yarspg/badge.svg)](https://coveralls.io/r/gkellogg/yarspg)

## Features

YARSPG parses CSV or other Tabular Data into [RDF*][].

* Nodes, properties, and string annotations are treated as document-relative fragments.
* Edges are emitted only to the default graph, with properties and annotations emitted either to the default graph, or the specifically named graph(s).
* Node labels are treated as as document-relative `rdf:type` values.
* List complex values are emitted as `rdf:Lists`.
* Set and Struct complex values are emitted as `rdf:JSON` literals.

## Installation
Install with `gem install yarspg`.

## Description

YARSPG parses [YARS-PG][] formatted documents into [RDF*][] datasets, where edges are RDF triples in the default graph, which form the subject of the properties and annotations on that edge.

There is currently no extra support for [Node Schemas](https://lszeremeta.github.io/yarspg/index.html#dfn-node-schema-declaration) or [Edge Schemas](https://lszeremeta.github.io/yarspg/index.html#dfn-edge-schema-declaration).

## Example

An example YARS-PG document follows:

    # Prefix declaration
    :foaf: <http://xmlns.com/foaf/0.1/>

    %METADATA
    -foaf:maker: "Łukasz Szeremeta and Dominik Tomaszuk"

    %NODES
    <"Author01">{"Author"}["fname": "John", "lname": "Smith"] #Author01
    <"Author02">{"Author"}["fname": "Alice", "lname": "Brown"]
    <"EI01">{"Entry", "InProceedings"}["title": "Serialization for...", "numpages": 10, "keyword": "Graph database"]
    <"EA01">{"Entry", "Article"}["title": "Property Graph...",  "numpages": 10, "keyword": ["Query", "Graph"]]
    <"Proc01">{"Proceedings"}["title": "BDAS", "year": 2018, "month": "May"]
    <"Jour01">{"Journal"}["title": "J. DB", "year": 2020, "vol": 30]

    %EDGES
    ("EI01")-{"has_author"}["order": 1]->("Author01")
    ("EI01")-{"has_author"}["order": 2]->("Author02")
    ("EA01")-{"has_author"}["order": 1]->("Author02")
    ("EA01")-{"cites"}->("EI01")
    ("EI01")-{"booktitle"}["pages": "111-121"]->("Proc01")
    ("EA01")-{"published_in"}["pages": "222-232"]->("Jour01")

This results in the following TriG*:

    @prefix foaf: <http://xmlns.com/foaf/0.1/> .
    @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
    @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

    <> foaf:maker "Łukasz Szeremeta and Dominik Tomaszuk" .

    <#Author01> a <#Author>; <#fname> "John"; <#lname> "Smith" .
    <#Author02> a <#Author>; <#fname> "Alice"; <#lname> "Brown" .

    <#EI01> a <#Entry>, <#InProceedings>;
      <#title> "Serialization for...";
      <#numpages> 10;
      <#keyword> "Graph database";
      <#booktitle> <#Proc01>;
      <#has_author> <#Author02>, <#Author01> .

    <#EA01> a <#Entry>, <#Article>;
      <#title> "Property Graph...";
      <#numpages> 10;
      <#keyword> ("Query" "Graph");
      <#cites> <#EI01>;
      <#has_author> <#Author02>;
      <#published_in> <#Jour01> .

    <#Proc01> a <#Proceedings>;
      <#month> "May";
      <#title> "BDAS";
      <#year> 2018 .

    <#Jour01> a <#Journal>;
      <#title> "J. DB";
      <#vol> 30;
      <#year> 2020 .

    <<<#EI01> <#has_author> <#Author01>>> <#order> 1 .
    <<<#EI01> <#has_author> <#Author02>>> <#order> 2 .
    <<<#EA01> <#has_author> <#Author02>>> <#order> 1 .
    <<<#EI01> <#booktitle> <#Proc01>>> <#pages> "111-121" .
    <<<#EA01> <#published_in> <#Jour01>>> <#pages> "222-232" .

## RDF Reader
YARS acts as a normal RDF reader, using the standard RDF.rb Reader interface:

    graph = RDF::Graph.load("etc/doap.yarspg")

alternatively

    graph = RDF::Graph.new {|g| YARSPG::Reader.open("etc/doap.yarspg") {|r| g << r}}

### Principal Classes
* {YARSPG}
  * {YARSPG::Format}
  * {YARSPG::Metadata}
  * {YARSPG::Reader}
  * {YARSPG::Terminals}

## Dependencies
* [Ruby](https://ruby-lang.org/) (>= 2.4)
* [RDF.rb][] (~> 3.1)
* [EBNF][] (~> 2.0)

## Installation
The recommended installation method is via [RubyGems](https://rubygems.org/).
To install the latest official release of the `RDF::Tabular` gem, do:

    % [sudo] gem install yarspg

## Mailing List
* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Author
* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>

## Contributing
* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `rdf-tabular.gemspec`, `VERSION` or `AUTHORS` files. If you need to change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.
  Note that the agreement applies to all repos in the [Ruby RDF](https://github.com/ruby-rdf/) organization.

## License

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[Ruby]:           https://ruby-lang.org/
[RDF]:            https://www.w3.org/RDF/
[YARD]:           https://yardoc.org/
[YARD-GS]:        https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[EBNF]:           https://rubygems.org/gems/ebnf
[RDF.rb]:         https://rubygems.org/gems/rdf
[RDF*]:           https://lists.w3.org/Archives/Public/public-rdf-star/
[YARS-PG]:        https://lszeremeta.github.io/yarspg/index.html
[Property Graph]: http://graphdatamodeling.com/Graph%20Data%20Modeling/GraphDataModeling/page/PropertyGraphs.html