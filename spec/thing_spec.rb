require 'spec_helper'
require 'thing'

describe Thing do

  context "creating an article from a page id" do
    before :each do
      @thing = Thing.new(52780)
    end

    it "should return an object of type Thing" do
      @thing.class.should == Thing
    end

    it "should have the correct URI" do
      @thing.uri.should == RDF::URI('http://www.dbpedialite.org/things/52780#id')
    end

    it "should not have co-ordinates" do
      @thing.should_not have_coordinates
    end
  end

  context "creating an thing with data provided" do
    before :each do
      @thing = Thing.new(
        :pageid => '934787',
        :title => 'Ceres, Fife',
        :displaytitle => 'Ceres, Fife',
        :latitude => 56.293431,
        :longitude => -2.970134,
        :updated_at => DateTime.parse('2010-05-08T17:20:04Z'),
        :abstract => "Ceres is a village in Fife, Scotland."
      )
    end

    it "should return an object of type Thing" do
      @thing.class.should == Thing
    end

    it "should have a pageid method to get the page id from the uri" do
      @thing.pageid.should == '934787'
    end

    it "should have the correct URI for the thing" do
      @thing.uri.should == RDF::URI('http://www.dbpedialite.org/things/934787#id')
    end

    it "should have the correct URI for the document" do
     @thing.doc_uri.should == RDF::URI('http://www.dbpedialite.org/things/934787')
    end

    it "should have the correct title" do
      @thing.title.should == 'Ceres, Fife'
    end

    it "should have the correct display title" do
      @thing.displaytitle.should == 'Ceres, Fife'
    end

    it "should have the correct abstract" do
      @thing.abstract.should == 'Ceres is a village in Fife, Scotland.'
    end

    it "should have the correct latitude" do
      @thing.latitude.should == 56.293431
    end

    it "should have the correct longitude" do
      @thing.longitude.should == -2.970134
    end

    it "should encode the Wikipedia page URL correctly" do
      @thing.wikipedia_uri.should == RDF::URI('http://en.wikipedia.org/wiki/Ceres,_Fife')
    end

    it "should encode the dbpedia URI correctly" do
      @thing.dbpedia_uri.should == RDF::URI('http://dbpedia.org/resource/Ceres,_Fife')
    end
  end

  context "changing the URI of the document" do
    before :each do
      @thing = Thing.new(1234)
    end

    it "should have the correct default URI for the document" do
      @thing.doc_uri.should == RDF::URI('http://www.dbpedialite.org/things/1234')
    end

    it "should return the new document URI after changing it" do
      @thing.doc_uri = 'http://127.0.0.1/foobar.rdf'
      @thing.doc_uri.should == RDF::URI('http://127.0.0.1/foobar.rdf')
    end
  end

  context "loading a page from wikipedia" do
    before :each do
      wikipedia_data = {
        'title' => 'Ceres, Fife',
        'displaytitle' => 'Ceres, Fife',
        'longitude' => -2.970134,
        'latitude' => 56.293431,
        'abstract' => 'Ceres is a village in Fife, Scotland',
        'images' => ['http://upload.wikimedia.org/wikipedia/commons/0/04/Ceres%2C_Fife.jpg'],
        'externallinks' => ['http://www.fife.50megs.com/ceres-history.htm']
      }
      allow(WikipediaApi).to receive(:parse).and_return(wikipedia_data)
      @thing = Thing.load(934787)
    end

    it "should return a Thing" do
      @thing.class.should == Thing
    end

    it "should have the correct page id" do
      @thing.pageid.should == 934787
    end

    it "should have the correct uri" do
      @thing.uri.should == RDF::URI('http://www.dbpedialite.org/things/934787#id')
    end

    it "should have the correct title" do
      @thing.title.should == 'Ceres, Fife'
    end

    it "should have co-ordinates" do
      @thing.should have_coordinates
    end

    it "should have the correct latitude" do
      @thing.latitude.should == 56.293431
    end

    it "should have the correct longitude" do
      @thing.longitude.should == -2.970134
    end

    it "should encode the Wikipedia page URL correctly" do
      @thing.wikipedia_uri.should == RDF::URI('http://en.wikipedia.org/wiki/Ceres,_Fife')
    end

    it "should encode the dbpedia URI correctly" do
      @thing.dbpedia_uri.should == RDF::URI('http://dbpedia.org/resource/Ceres,_Fife')
    end

    it "should extract the abstract correctly" do
      @thing.abstract.should =~ /^Ceres is a village in Fife, Scotland/
    end

    it "should have a single external like of type RDF::URI" do
      @thing.externallinks.should == [RDF::URI('http://www.fife.50megs.com/ceres-history.htm')]
    end

    #it "should have a single image of type RDF::URI" do
    #  @thing.images.should == [RDF::URI('http://upload.wikimedia.org/wikipedia/commons/0/04/Ceres%2C_Fife.jpg')]
    #end
  end

  context "loading a non-existant page from wikipedia" do
    before :each do
      allow(WikipediaApi).to receive(:parse).and_raise(
        MediaWikiApi::NotFound,
        'There is no page with ID 999999'
      )
    end
  end

  context "converting a thing to RDF" do
    before :each do
      allow(WikidataApi).to receive(:find_by_title).and_return({
        'id' => 'q396',
        'title'=> 'Q396',
        'pageid' => 602,
        'labels' => {'en' => {'language' => 'en', 'value' => 'U2'}},
        'descriptions' =>
          {'en' =>
            {'language' => 'en', 'value' => 'Irish rock band from Dublin formed in 1976'}},
        'lastrevid' => 1416446,
        'ns' => 0,
        'type' => 'item',
        'modified' => '2012-12-13T08:20:29Z',
      })
      @thing = Thing.new(52780,
        :title => 'U2',
        :displaytitle => 'U2',
        :abstract => 'U2 are an Irish rock band.',
        :updated_at => DateTime.parse('2010-05-08T17:20:04Z')
      )
      @graph = @thing.to_rdf
    end

    it "should return an RDF::Graph" do
      @graph.class.should == RDF::Graph
    end

    it "should return a graph with 20 triples" do
      @graph.count.should == 20
    end

    it "should include an rdf:type triple for the thing" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780#id"),
        RDF.type,
        RDF::URI("http://www.w3.org/2002/07/owl#Thing")
      ])
    end

    it "should include a rdfs:label triple for the thing" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780#id"),
        RDF::RDFS.label,
        RDF::Literal("U2"),
      ])
    end

    it "should include a rdfs:comment triple for the thing" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780#id"),
        RDF::RDFS.comment,
        RDF::Literal("U2 are an Irish rock band."),
      ])
    end

    it "should include a owl:sameAs triple for the Dbpedia URI" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780#id"),
        RDF::OWL.sameAs,
        RDF::URI("http://dbpedia.org/resource/U2")
      ])
    end

    it "should include a isPrimaryTopicOf triple for the Wikipedia page" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780#id"),
        RDF::FOAF.isPrimaryTopicOf,
        RDF::URI("http://en.wikipedia.org/wiki/U2")
      ])
    end

    it "should include a foaf:page triple for Wikidata page" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780#id"),
        RDF::OWL.sameAs,
        RDF::URI('http://www.wikidata.org/entity/Q396')
      ])
    end

    it "should include a rdf:type triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780"),
        RDF.type,
        RDF::URI("http://xmlns.com/foaf/0.1/Document")
      ])
    end

    it "should include a foaf:primaryTopic triple linking the document to the thing" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780"),
        RDF::FOAF.primaryTopic,
        RDF::URI("http://www.dbpedialite.org/things/52780#id")
      ])
    end

    it "should include a dc:title triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780"),
        RDF::URI("http://purl.org/dc/terms/title"),
        RDF::Literal('dbpedia lite thing - U2')
      ])
    end

    it "should include a dc:modified triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780"),
        RDF::URI("http://purl.org/dc/terms/modified"),
        RDF::Literal(DateTime.parse('2010-05-08T17:20:04Z'))
      ])
    end

    it "should include a cc:license, CC-BY-SA 3.0, triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780"),
        RDF::URI("http://creativecommons.org/ns#license"),
        RDF::URI("http://creativecommons.org/licenses/by-sa/3.0/")
      ])
    end

    it "should include a cc:license, GNU FDL 1.3, triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://www.dbpedialite.org/things/52780"),
        RDF::URI("http://creativecommons.org/ns#license"),
        RDF::URI("http://gnu.org/licenses/fdl-1.3.html")
      ])
    end


  end
end
