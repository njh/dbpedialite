require File.dirname(__FILE__) + "/spec_helper.rb"
require 'wikipedia_category'

describe WikipediaCategory do

  context "creating a category from a page id" do
    before :each do
      @category = WikipediaCategory.new(4309010)
    end

    it "should return an object of type WikipediaCategory" do
      @category.class.should == WikipediaCategory
    end

    it "should have the correct URI" do
      @category.uri.should == RDF::URI('http://dbpedialite.org/categories/4309010#category')
    end
  end

  context "create a category from a hash" do
    before :each do
      @category = WikipediaCategory.new(
        'pageid' => 4309010,
        'ns' => 14,
        'title' => 'Category:Villages in Fife'
      )
    end

    it "should return an object of type WikipediaCategory" do
      @category.class.should == WikipediaCategory
    end

    it "should have the correct URI" do
      @category.uri.should == RDF::URI('http://dbpedialite.org/categories/4309010#category')
    end

    it "should have the correct title" do
      @category.title.should == 'Category:Villages in Fife'
    end

    it "should have the correct label" do
      @category.label.should == 'Villages in Fife'
    end

  end

  context "converting a category to RDF" do
    before :each do
      @category = WikipediaCategory.new(4309010,
        :title => 'Category:Villages in Fife',
        :abstract => "U2 are an Irish rock band.",
        :things => [
          WikipediaThing.new(1137426, :title => "Anstruther"),
          WikipediaThing.new(52780, :title => "Ceres, Fife")
        ]
      )
      @graph = @category.to_rdf
    end

    it "should return an RDF::Graph" do
      @graph.class.should == RDF::Graph
    end

    it "should return a graph with 8 triples" do
      @graph.count.should == 11
    end

    it "should include an rdf:type triple for the category" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/categories/4309010#category"),
        RDF.type,
        RDF::SKOS.Concept
      ])
    end

    it "should include a rdfs:label triple for the category" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/categories/4309010#category"),
        RDF::RDFS.label,
        RDF::Literal("Villages in Fife"),
      ])
    end

    it "should include a rdf:type triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/categories/4309010"),
        RDF.type,
        RDF::URI("http://xmlns.com/foaf/0.1/Document")
      ])
    end

    it "should include a foaf:primaryTopic triple linking the document to the category" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/categories/4309010"),
        RDF::FOAF.primaryTopic,
        RDF::URI("http://dbpedialite.org/categories/4309010#category")
      ])
    end

    it "should have a SKOS:subject triple relating Ceres to Villages in Fife" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780#thing"),
        RDF::SKOS.subject,
        RDF::URI("http://dbpedialite.org/categories/4309010#category")
      ])
    end
  end
end
