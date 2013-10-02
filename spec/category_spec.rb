require 'spec_helper'
require 'category'

describe Category do

  context "creating a category from a page id" do
    before :each do
      @category = Category.new(4309010)
    end

    it "should return an object of type Category" do
      @category.class.should == Category
    end

    it "should have the correct URI" do
      @category.uri.should == RDF::URI('http://dbpedialite.org/categories/4309010#id')
    end

    it "should not have any things yet" do
      @category.things.count.should == 0
    end
  end

  context "create a category from a hash" do
    before :each do
      @category = Category.new(
        'pageid' => 4309010,
        'ns' => 14,
        'title' => 'Category:Villages in Fife',
        'displaytitle' => 'Category:Villages in Fife'
      )
    end

    it "should return an object of type Category" do
      @category.class.should == Category
    end

    it "should have the correct URI" do
      @category.uri.should == RDF::URI('http://dbpedialite.org/categories/4309010#id')
    end

    it "should have the correct title" do
      @category.title.should == 'Category:Villages in Fife'
    end

    it "should have the correct diaplay title" do
      @category.title.should == 'Category:Villages in Fife'
    end

    it "should have the correct label" do
      @category.label.should == 'Villages in Fife'
    end
  end

  context "loading a category from the Wikipedia API" do
    before :each do
      page_info = {
        'pageid' => 4309010,
        'ns' => 14,
        'title' => 'Category:Villages in Fife',
        'displaytitle' => 'Category:Villages in Fife',
        'touched' => '2010-11-04T04:11:11Z',
        'lastrevid' => 325602311,
        'counter' => 0,
        'length' => 259
      }
      category_members = [
        {'pageid' => 2712,'ns' => 0, 'title' => 'Aberdour', 'displaytitle' => 'Aberdour'},
        {'pageid' => 934787, 'ns' => 0, 'title' => 'Ceres, Fife', 'displaytitle' => 'Ceres, Fife'},
        {'pageid' => 986129, 'ns' => 14, 'title' => 'Category:Villages with greens', 'displaytitle' => 'Category:Villages with greens'}
      ]
      allow(WikipediaApi).to receive(:page_info).with(:pageids => 4309010).and_return(page_info)
      allow(WikipediaApi).to receive(:category_members).with(4309010).and_return(category_members)
      @category = Category.load(4309010)
    end

    it "should have the correct page id" do
      @category.pageid.should == 4309010
    end

    it "should have the correct uri" do
      @category.uri.should == RDF::URI('http://dbpedialite.org/categories/4309010#id')
    end

    it "should have the correct title" do
      @category.title.should == 'Category:Villages in Fife'
    end

    it "should have a label without the 'Category' prefix in it" do
      @category.label.should == 'Villages in Fife'
    end

    it "should have 2 things associated with the category" do
      @category.things.count.should == 2
    end

    it "should have a first thing of class Thing" do
      @category.things.first.class.should == Thing
    end

    it "should have a first thing with title Aberdour" do
      @category.things.first.title.should == 'Aberdour'
    end

    it "should have one sub-category" do
      @category.subcategories.count.should == 1
    end

    it "should have a first subcategory of class Category" do
      @category.subcategories.first.class.should == Category
    end

    it "should have a first subcategory with label Villages with greens" do
      @category.subcategories.first.label.should == 'Villages with greens'
    end
  end

  context "loading a non-category page from wikipedia" do
    before :each do
      page_info = {
        'pageid' => 52780,
        'ns' => 0,
        'title' => 'U2',
        'displaytitle' => 'U2',
        'touched' => '2010-05-12T22:44:49Z',
        'lastrevid' => 361771300,
        'counter' => 787,
        'length' => 78367
      }
      allow(WikipediaApi).to receive(:page_info).with(:pageids => 52780).and_return(page_info)
    end

    it "should return raise a PageNotFound exception" do
      lambda {Category.load(52780)}.should raise_error(
        MediaWikiApi::NotFound,
        'Page 52780 is not a category'
      )
    end
  end

  context "converting a category to RDF" do
    before :each do
      @category = Category.new(4309010,
        :title => 'Category:Villages in Fife',
        :displaytitle => 'Category:Villages in Fife',
        :abstract => "Villages located in Fife, Scotland.",
        :things => [
          Thing.new(1137426, :title => "Anstruther"),
          Thing.new(52780, :title => "Ceres, Fife")
        ],
        :subcategories => [
          Category.new(1234567,
            :title => 'Category:Hamlets in Fife',
            :displaytitle => 'Category:Hamlets in Fife'
          )
        ]
      )
      @graph = @category.to_rdf
    end

    it "should return an RDF::Graph" do
      @graph.class.should == RDF::Graph
    end

    it "should return a graph with 13 triples" do
      @graph.count.should == 13
    end

    it "should include an rdf:type triple for the category" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/categories/4309010#id"),
        RDF.type,
        RDF::OWL.Class
      ])
    end

    it "should include a rdfs:label triple for the category" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/categories/4309010#id"),
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

    it "should include a dc:title triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/categories/4309010"),
        RDF::URI("http://purl.org/dc/terms/title"),
        RDF::Literal('dbpedia lite category - Villages in Fife')
      ])
    end

    it "should include a foaf:primaryTopic triple linking the document to the category" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/categories/4309010"),
        RDF::FOAF.primaryTopic,
        RDF::URI("http://dbpedialite.org/categories/4309010#id")
      ])
    end

    it "should have a RDF:type triple relating Ceres to Villages in Fife" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780#id"),
        RDF.type,
        RDF::URI("http://dbpedialite.org/categories/4309010#id")
      ])
    end

    it "should have a RDFS:subClassOf triple subclassing Hamlets from Villages" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/categories/1234567#id"),
        RDF::RDFS.subClassOf,
        RDF::URI("http://dbpedialite.org/categories/4309010#id")
      ])
    end
  end
end
