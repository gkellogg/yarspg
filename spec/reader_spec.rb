# coding: utf-8
$:.unshift "."
require 'spec_helper'
require 'rdf/spec/reader'

describe YARSPG::Reader do
  let!(:doap) {File.expand_path("../../etc/doap.yarspg", __FILE__)}
  let!(:doap_count) {23}
  after(:each) {|example| puts @logger.to_s if example.exception}

  it_behaves_like 'an RDF::Reader' do
    let(:reader) {YARSPG::Reader.new}
    let(:reader_input) {File.read(doap)}
    let(:reader_count) {doap_count}
  end

  describe ".for" do
    [
      :yarspg,
      'etc/doap.yarspg',
      {file_name:       'etc/doap.yarspg'},
      {file_extension:  'yarspg'},
      {content_type:    'text/yarspg'},
    ].each do |arg|
      it "discovers with #{arg.inspect}" do
        expect(RDF::Reader.for(arg)).to eq YARSPG::Reader
      end
    end
  end

  context :interface do
    subject {
      %q(
        :: <http://example/>
        -<b>: <C>
      )
    }
    
    it "should yield reader" do
      inner = double("inner")
      expect(inner).to receive(:called).with(YARSPG::Reader)
      YARSPG::Reader.new(subject) do |reader|
        inner.called(reader.class)
      end
    end
    
    it "should return reader" do
      expect(YARSPG::Reader.new(subject)).to be_a(YARSPG::Reader)
    end

    it "should not raise errors" do
      expect {
        YARSPG::Reader.new(subject, validate:  true)
      }.not_to raise_error
    end

    it "should yield statements" do
      inner = double("inner")
      expect(inner).to receive(:called).with(RDF::Statement).exactly(1)
      YARSPG::Reader.new(subject).each_statement do |statement|
        inner.called(statement.class)
      end
    end
    
    it "should yield triples" do
      inner = double("inner")
      expect(inner).to receive(:called).exactly(1)
      YARSPG::Reader.new(subject).each_triple do |subject, predicate, object|
        inner.called(subject.class, predicate.class, object.class)
      end
    end
  end

  describe "with simple metadata" do
    context "simple triple" do
      before(:each) do
        input = %(-<http://xmlns.com/foaf/0.1/name>: "Gregg Kellogg")
        @graph = parse(input, validate:  true, base_uri: 'http://example/')
        @statement = @graph.statements.to_a.first
      end
      
      it "should have a single triple" do
        expect(@graph.size).to eq 1
      end
      
      it "should have subject" do
        expect(@statement.subject.to_s).to eq "http://example/"
      end
      it "should have predicate" do
        expect(@statement.predicate.to_s).to eq "http://xmlns.com/foaf/0.1/name"
      end
      it "should have object" do
        expect(@statement.object.to_s).to eq "Gregg Kellogg"
      end
    end
    
    context "simple pname" do
      before(:each) do
        input = %(
          :foaf: <http://xmlns.com/foaf/0.1/>
          -foaf:name: "Gregg Kellogg"
        )
        @graph = parse(input, validate:  true, base_uri: 'http://example/')
        @statement = @graph.statements.to_a.first
      end
      
      it "should have a single triple" do
        expect(@graph.size).to eq 1
      end
      
      it "should have subject" do
        expect(@statement.subject.to_s).to eq "http://example/"
      end
      it "should have predicate" do
        expect(@statement.predicate.to_s).to eq "http://xmlns.com/foaf/0.1/name"
      end
      it "should have object" do
        expect(@statement.object.to_s).to eq "Gregg Kellogg"
      end
    end
    
    context "IRI pname" do
      before(:each) do
        input = %(
          :foaf: <http://xmlns.com/foaf/0.1/>
          -foaf:maker: <https://greggkellogg.net/foaf#me>
        )
        @graph = parse(input, validate:  true, base_uri: 'http://example/')
        @statement = @graph.statements.to_a.first
      end
      
      it "should have a single triple" do
        expect(@graph.size).to eq 1
      end
      
      it "should have subject" do
        expect(@statement.subject.to_s).to eq "http://example/"
      end
      it "should have predicate" do
        expect(@statement.predicate.to_s).to eq "http://xmlns.com/foaf/0.1/maker"
      end
      it "should have object" do
        expect(@statement.object.to_s).to eq "https://greggkellogg.net/foaf#me"
      end
    end
    
    describe "with blank lines" do
      {
        "comment"                   => "# comment lines",
        "comment after whitespace"  => "            # comment after whitespace",
        "empty line"                => "",
        "line with spaces"          => "      "
      }.each_pair do |name, statement|
        specify "test #{name}" do
          expect(parse(statement).size).to eq 0
        end
      end
    end

    describe "with literal encodings" do
      {
        #'simple literal' => '-<b>: "simple literal"',
        'backslash:\\'   => '-<b>: "backslash:\\\\"',
        'dquote:"'       => '-<b>: "dquote:\\""',
        "newline:\n"     => '-<b>: "newline:\\n"',
        "return\r"       => '-<b>: "return\\r"',
        "tab:\t"         => '-<b>: "tab:\\t"',
      }.each_pair do |contents, triple|
        specify "test #{triple}", pending: "support for escapes in strings" do
          graph = parse(triple, validate: false)
          statement = graph.statements.to_a.first
          expect(graph.size).to eq 1
          expect(statement.object.value).to eq contents
        end
      end
      
      # Rubinius problem with UTF-8 indexing:
      # "\"D\xC3\xBCrst\""[1..-2] => "D\xC3\xBCrst\""
      {
        'Dürst' => '-<b>: "Dürst"',
        "é"     => '-<b>:  "é"',
        "€"     => '-<b>:  "€"',
        "resumé"=> '-<b>:  "resumé"',
      }.each_pair do |contents, triple|
        specify "test #{triple}" do
          graph = parse(triple, validate: false)
          statement = graph.statements.to_a.first
          expect(graph.size).to eq 1
          expect(statement.object.value).to eq contents
        end
      end
    end

    describe "IRIs" do
      {
        %(:: <http://a/b/> -<http://xmlns.com/foaf/0.1/knows>: <http://example/jane>) =>
          %(<http://a/b/> <http://xmlns.com/foaf/0.1/knows> <http://example/jane> .),
        %(:: <http://a/joe> -<knows>: <#jane>) =>
          %(<http://a/joe> <http://a/knows> <http://a/joe#jane> .),
        %(:: <http://a/b#> -<knows>: <#jane>) =>
          %(<http://a/b#> <http://a/knows> <http://a/b#jane> .),
        %(:: <http://a/b/> -<knows>: <#jane>) =>
          %(<http://a/b/> <http://a/b/knows> <http://a/b/#jane> .),
        %(:: <http://a/b/> -<knows>: <jane>) =>
          %(<http://a/b/> <http://a/b/knows> <http://a/b/jane> .),
        %(:: <http://a/b/> -<a>: <http://example/#D%C3%BCrst>) =>
          %(<http://a/b/> <http://a/b/a> <http://example/#D%C3%BCrst> .),
        %q(:: <http://a/b/> -<a>: <scheme:!$%25&'()*+,-./0123456789:/@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~?#>) =>
          %q(<http://a/b/> <http://a/b/a> <scheme:!$%25&'()*+,-./0123456789:/@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~?#> .),
      }.each_pair do |ypg, nt|
        it "for '#{ypg}'" do
          expect(parse(ypg, validate:  true)).to be_equivalent_graph(nt, logger: @logger)
        end
      end

      [
        %(\x00),
        %(\x01),
        %(\x0f),
        %(\x10),
        %(\x1f),
        %(\x20),
        %(<),
        %(>),
        %("),
        %({),
        %(}),
        %(|),
        %(\\),
        %(^),
        %(``),
        %(http://example.com/\u0020),
        %(http://example.com/\u003C),
        %(http://example.com/\u003E),
      ].each do |uri|
        it "rejects #{('<' + uri + '>').inspect}" do
          expect {parse(%(-<http://example/p>: <#{uri}>), validate:  true)}.to raise_error RDF::ReaderError
        end
      end
    end
  end

  describe "nodes" do
  end

  describe "edges" do
  end

  describe "examples" do
    {
    }.each do |name, (input, expected)|
      it "matches YARS-PG spec #{name}" do
        g2 = parse(expected, validate: false, format: :trig)
        g1 = parse(input, validate: false)
        expect(g1).to be_equivalent_graph(g2, logger: @logger)
      end
    end
  end

  def parse(input, **options)
    @logger = RDF::Spec.logger
    options = {
      logger: @logger,
      validate:  true,
      canonicalize:  false,
    }.merge(options)
    graph = options[:graph] || RDF::Graph.new
    reader = RDF::Reader.for(options.fetch(:format, :yarspg))
    reader.new(input, **options).each do |statement|
      graph << statement
    end
    graph
  end
end
