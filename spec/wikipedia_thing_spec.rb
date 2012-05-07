require 'spec_helper'
require 'wikipedia_thing'

describe WikipediaThing do

  context "creating an article from a page id" do
    before :each do
      @thing = WikipediaThing.new(52780)
    end

    it "should return an object of type WikipediaThing" do
      @thing.class.should == WikipediaThing
    end

    it "should have the correct URI" do
      @thing.uri.should == RDF::URI('http://dbpedialite.org/things/52780#id')
    end

    it "should not have co-ordinates" do
      @thing.should_not have_coordinates
    end
  end

  context "creating an thing with data provided" do
    before :each do
      @thing = WikipediaThing.new(
        :pageid => '934787',
        :title => 'Ceres, Fife',
        :displaytitle => 'Ceres, Fife',
        :latitude => 56.293431,
        :longitude => -2.970134,
        :updated_at => DateTime.parse('2010-05-08T17:20:04Z'),
        :abstract => "Ceres is a village in Fife, Scotland."
      )
    end

    it "should return an object of type WikipediaThing" do
      @thing.class.should == WikipediaThing
    end

    it "should have a pageid method to get the page id from the uri" do
      @thing.pageid.should == '934787'
    end

    it "should have the correct URI for the thing" do
      @thing.uri.should == RDF::URI('http://dbpedialite.org/things/934787#id')
    end

    it "should have the correct URI for the document" do
     @thing.doc_uri.should == RDF::URI('http://dbpedialite.org/things/934787')
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
      @thing = WikipediaThing.new(1234)
    end

    it "should have the correct default URI for the document" do
      @thing.doc_uri.should == RDF::URI('http://dbpedialite.org/things/1234')
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
      WikipediaApi.expects(:parse).once.returns(wikipedia_data)
      @thing = WikipediaThing.load(934787)
    end

    it "should return a WikipediaThing" do
      @thing.class.should == WikipediaThing
    end

    it "should have the correct page id" do
      @thing.pageid.should == 934787
    end

    it "should have the correct uri" do
      @thing.uri.should == RDF::URI('http://dbpedialite.org/things/934787#id')
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

    it "should escape titles correctly" do
      @thing.escaped_title.should == 'Ceres,_Fife'
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

    context "when freebase responds with a parsable response" do
      before :each do
        freebase_data = {
          'guid' => '#9202a8c04000641f80000000003bb45c',
          'id' => '/en/ceres_united_kingdom',
          'mid' => '/m/03rf2x',
          'name' => 'Ceres',
        }
        FreebaseApi.expects(:lookup_wikipedia_pageid).once.returns(freebase_data)
      end

      it "should have a freebase URI based on the machine id" do
        @thing.freebase_mid_uri.should == RDF::URI('http://rdf.freebase.com/ns/m.03rf2x')
      end

      it "should have a freebase URI based on the guid" do
        @thing.freebase_guid_uri.should == RDF::URI('http://rdf.freebase.com/ns/guid.9202a8c04000641f80000000003bb45c')
      end
    end

    context "when freebase times out" do
      it "should send a message to stderr" do
        FreebaseApi.expects(:lookup_wikipedia_pageid).raises(Timeout::Error)
        previous_stderr, $stderr = $stderr, StringIO.new

        @thing.freebase_mid_uri
        $stderr.string.should == "Timed out while reading from Freebase: Timeout::Error\n"

        $stderr = previous_stderr
      end
    end

    context "when FreebaseApi raises any error other than timeout" do
      it "should send a message to stderr" do
        FreebaseApi.expects(:lookup_wikipedia_pageid).raises()
        previous_stderr, $stderr = $stderr, StringIO.new

        @thing.freebase_mid_uri
        $stderr.string.should == "Error while reading from Freebase: RuntimeError\n"

        $stderr = previous_stderr
      end
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
      WikipediaApi.expects(:parse).once.raises(
        WikipediaApi::PageNotFound,
        'There is no page with ID 999999'
      )
      FreebaseApi.expects(:lookup_wikipedia_pageid).never
    end

    it "should return raise a PageNotFound exception" do
      lambda {WikipediaThing.load(999999)}.should raise_error(
        WikipediaApi::PageNotFound,
        'There is no page with ID 999999'
      )
    end
  end

  context "converting a thing to RDF" do
    before :each do
      FreebaseApi.expects(:lookup_wikipedia_pageid).once.returns({
        'guid' => '#9202a8c04000641f8000000000066c8e',
        'id' => '/en/u2',
        'mid' => '/m/0dw4g',
        'name' => 'U2',
      })
      WikipediaApi.expects(:parse).never
      @thing = WikipediaThing.new(52780,
        :title => 'U2',
        :displaytitle => 'U2',
        :abstract => "U2 are an Irish rock band.",
        :updated_at => DateTime.parse('2010-05-08T17:20:04Z')
      )
      @graph = @thing.to_rdf
    end

    it "should return an RDF::Graph" do
      @graph.class.should == RDF::Graph
    end

    it "should return a graph with 11 triples" do
      @graph.count.should == 11
    end

    it "should include an rdf:type triple for the thing" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780#id"),
        RDF.type,
        RDF::URI("http://www.w3.org/2002/07/owl#Thing")
      ])
    end

    it "should include a rdfs:label triple for the thing" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780#id"),
        RDF::RDFS.label,
        RDF::Literal("U2"),
      ])
    end

    it "should include a rdfs:comment triple for the thing" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780#id"),
        RDF::RDFS.comment,
        RDF::Literal("U2 are an Irish rock band."),
      ])
    end

    it "should include a owl:sameAs triple for the Dbpedia URI" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780#id"),
        RDF::OWL.sameAs,
        RDF::URI("http://dbpedia.org/resource/U2")
      ])
    end

    it "should include a isPrimaryTopicOf triple for the Wikipedia page" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780#id"),
        RDF::FOAF.isPrimaryTopicOf,
        RDF::URI("http://en.wikipedia.org/wiki/U2")
      ])
    end

    it "should include a owl:sameAs triple for the FreeBase Machine ID" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780#id"),
        RDF::OWL.sameAs,
        RDF::URI("http://rdf.freebase.com/ns/m.0dw4g")
      ])
    end

    it "should include a owl:sameAs triple for the FreeBase GUID" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780#id"),
        RDF::OWL.sameAs,
        RDF::URI("http://rdf.freebase.com/ns/guid.9202a8c04000641f8000000000066c8e")
      ])
    end

    it "should include a rdf:type triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780"),
        RDF.type,
        RDF::URI("http://xmlns.com/foaf/0.1/Document")
      ])
    end

    it "should include a foaf:primaryTopic triple linking the document to the thing" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780"),
        RDF::FOAF.primaryTopic,
        RDF::URI("http://dbpedialite.org/things/52780#id")
      ])
    end

    it "should include a dc:title triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780"),
        RDF::URI("http://purl.org/dc/terms/title"),
        RDF::Literal('dbpedia lite thing - U2')
      ])
    end

    it "should include a dc:modified triple for the document" do
      @graph.should have_triple([
        RDF::URI("http://dbpedialite.org/things/52780"),
        RDF::URI("http://purl.org/dc/terms/modified"),
        RDF::Literal(DateTime.parse('2010-05-08T17:20:04Z'))
      ])
    end

  end
end
