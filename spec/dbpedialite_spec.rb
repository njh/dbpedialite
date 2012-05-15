require 'spec_helper'
require 'dbpedialite'


## Note: these are integration tests. Mocking is done using FakeWeb.

set :environment, :test

describe 'dbpedia lite' do
  include Rack::Test::Methods

  def app
    DbpediaLite
  end

  before :each do
    app.enable :raise_errors
    app.disable :show_exceptions
  end

  context "GETing the homepage" do
    context "in a non-production environment" do
      before :each do
        get '/'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type text/html" do
        last_response.content_type.should == 'text/html;charset=utf-8'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end

      it "should contain the readme text" do
        last_response.body.should =~ /takes some of the structured data/
      end
      it "should contain the bookmarklet" do
        last_response.body.should =~ %r|javascript:location.href='http://example.org/flipr\?url=|
      end
    end

    context "in a production environment" do
      before :each do
        set :environment, :production
        get '/'
      end

      after :each do
        set :environment, :test
      end

      it "should redirect" do
        last_response.status.should == 301
        last_response.location.should == 'http://dbpedialite.org/'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end
  end

  context "GETing a search page with a query string" do
    before :each do
      FakeWeb.register_uri(
        :get, %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('search-rat.json'),
        :content_type => 'application/json'
      )
      get '/search?term=rat'
    end

    it "should be successful" do
      last_response.should be_ok
    end

    it "should be text/html" do
      last_response.content_type.should == 'text/html;charset=utf-8'
    end

    it "should contain an escaped link to a title page" do
      last_response.body.should =~ %r[<a href=\"/titles/Brown_rat\">Brown rat</a>]
    end

    it "should contain snippets" do
      last_response.body.should =~ %r[The brown <span class='searchmatch'>rat</span>]
    end
  end

  context "GETing a search page with a query string (from jquery autocomplete)" do
    before :each do
      FakeWeb.register_uri(
        :get, %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('search-rat.json'),
        :content_type => 'application/json'
      )
      get '/search.json?term=rat'
    end

    it "should be successful" do
      last_response.should be_ok
    end

    it "should be text/json" do
      last_response.content_type.should == 'text/json;charset=utf-8'
    end

    it "should contain the search term" do
      last_response.body.should =~ %r[Rat]
    end
  end

  context "GETing the search page for unsupport format" do
    before :each do
      FakeWeb.register_uri(
        :get, %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('search-rat.json'),
        :content_type => 'application/json'
      )
      get '/search.ratrat?term=rat'
    end

    it "should return a 400 error" do
      last_response.should be_client_error
    end

    it "should include the text 'Unsupported format' in the body" do
      last_response.body.should =~ /Unsupported format/i
    end
  end

  context "GETing the search page without a query string" do
    before :each do
      get '/search'
    end

    it "should be a redirect" do
      last_response.should be_redirect
    end

    it "should set the location header to redirect to /" do
      last_response.location.should == 'http://example.org/'
    end
  end

  context "GETing a title URL for a thing" do
    before :each do
      FakeWeb.register_uri(
        :get, %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('pageinfo-u2.json'),
        :content_type => 'application/json'
      )
      get '/titles/U2'
    end

    it "should be a redirect" do
      last_response.should be_redirect
    end

    it "should set the location header to redirect to /" do
      last_response.location.should == 'http://example.org/things/52780'
    end

    it "should be cachable" do
      last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
    end
  end

  context "GETing a title URL for a category" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&prop=info&redirects=1&titles=Category:Villages_in_Fife',
        :body => fixture_data('pageinfo-villagesinfife.json'),
        :content_type => 'application/json'
      )
      get '/titles/Category:Villages_in_Fife'
    end

    it "should be a redirect" do
      last_response.should be_redirect
    end

    it "should set the location header to redirect to the category page" do
      last_response.location.should == 'http://example.org/categories/4309010'
    end

    it "should be cachable" do
      last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
    end
  end

  context "GETing an invalid title URL" do
    before :each do
      FakeWeb.register_uri(
        :get, %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('pageinfo-zsefpfs.json'),
        :content_type => 'application/json'
      )
      get '/titles/zsefpfs'
    end

    it "should return 404 Not Found" do
      last_response.should be_not_found
    end
  end

  context "GETing a title that isn't a thing" do
    before :each do
      FakeWeb.register_uri(
        :get, %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('pageinfo-user.json'),
        :content_type => 'application/json'
      )
      get '/titles/User:Nhumfrey'
    end

    it "should be an error" do
      last_response.should be_server_error
    end

    it "should inform the user that the namespace isn't supported" do
      last_response.body.should =~ /Unsupported Wikipedia namespace/
    end
  end

  context "GETing a geographic thing" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=934787&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-934787.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, %r[http://www.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-934787.json'),
        :content_type => 'application/json'
      )
    end

    context "as an HTML document" do
      before :each do
        header "Accept", "text/html"
        get '/things/934787'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type text/html" do
        last_response.content_type.should == 'text/html;charset=utf-8'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end

      it "should contain the first paragraph of the abstract for the thing" do
        last_response.body.should =~ /Ceres is a village in Fife, Scotland/
      end

      it "should contain not contain the paragraph after the table of contents" do
        last_response.body.should_not =~ /It is one of the most historic and picturesque villages in Scotland/
      end

      it "should have a Google Map on the page" do
        last_response.body.should =~ %r[<div id="map"></div>]
      end

      it "should include the title of the thing in the page title" do
        last_response.body.should =~ %r[<title>dbpedia lite - Ceres, Fife</title>]
      end

      it "should include a <meta> description tag with a truncated abstract" do
        last_response.body.should =~ %r[<meta name="description" content="Ceres is a village in Fife, Scotland]
      end

      it "should have the title of the thing as RDFa" do
        rdfa_graph.should have_triple([
                                       RDF::URI("http://dbpedialite.org/things/934787#id"),
                                       RDF::RDFS.label,
                                       RDF::Literal("Ceres, Fife")
                                      ])
      end

      it "should have a link to the Wikipedia page in the RDFa" do
        rdfa_graph.should have_triple([
                                       RDF::URI("http://dbpedialite.org/things/934787#id"),
                                       RDF::FOAF.isPrimaryTopicOf,
                                       RDF::URI("http://en.wikipedia.org/wiki/Ceres,_Fife"),
                                      ])
      end

      it "should have a link to an external link in the RDFa" do
        rdfa_graph.should have_triple([
                                       RDF::URI("http://dbpedialite.org/things/934787#id"),
                                       RDF::FOAF.page,
                                       RDF::URI("http://www.fife.50megs.com/ceres-history.htm"),
                                      ])
      end

      it "should have an RDFa triple linking the document to the thing" do
        rdfa_graph.should have_triple([
                                       RDF::URI("http://dbpedialite.org/things/934787"),
                                       RDF::FOAF.primaryTopic,
                                       RDF::URI("http://dbpedialite.org/things/934787#id"),
                                      ])
      end

      it "should have an dc:modified RDFa triple for the document" do
        rdfa_graph.should have_triple([
                                       RDF::URI("http://dbpedialite.org/things/934787"),
                                       RDF::URI("http://purl.org/dc/terms/modified"),
                                       RDF::Literal('2012-05-05T04:35:21Z')
                                      ])
      end

      it "should have an RDFa triple linking the altenate RDF/XML format" do
        rdfa_graph.should have_triple([
                                       RDF::URI("http://dbpedialite.org/things/934787"),
                                       RDF::URI("http://www.w3.org/1999/xhtml/vocab#alternate"),
                                       RDF::URI("http://dbpedialite.org/things/934787.rdf"),
                                      ])
      end

    end


    context "as an N-Triples document" do
      before :each do
        FakeWeb.register_uri(
          :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=934787&prop=text',
          :body => fixture_data('parse-934787.json'),
          :content_type => 'application/json'
        )
        FakeWeb.register_uri(
          :get, %r[http://www.freebase.com/api/service/mqlread],
          :body => fixture_data('freebase-mqlread-934787.json'),
          :content_type => 'application/json'
        )
        header "Accept", "text/plain"
        get '/things/934787'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type text/plain" do
        last_response.content_type.should == 'text/plain;charset=utf-8'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "as a JSON document" do
      before :each do
        header "Accept", "application/json"
        get '/things/934787'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type application/json" do
        last_response.content_type.should == 'application/json;charset=utf-8'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "as an Turtle document" do
      before :each do
        header "Accept", "text/turtle"
        get '/things/934787'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type text/turtle" do
        last_response.content_type.should == 'text/turtle;charset=utf-8'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end

      it "should set the RDFS prefix correctly" do
        last_response.body.should =~ %r[@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> \.]
      end

      it "should set the FOAF prefix correctly" do
        last_response.body.should =~ %r[@prefix foaf: <http://xmlns.com/foaf/0.1/> \.]
      end

      it "should contain a rdfs:label triple" do
        last_response.body.should =~ %r[rdfs:label "Ceres, Fife";]
      end
    end

    context "as an RDF/XML document by content negotiation" do
      before :each do
        header "Accept", "application/rdf+xml"
        get '/things/934787'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type application/rdf+xml" do
        last_response.content_type.should == 'application/rdf+xml'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end

      it "should have a XML declaration in the first line of the response" do
        lines = last_response.body.split(/[\r\n]+/)
        lines.first.should == '<?xml version="1.0" encoding="UTF-8"?>'
      end

      it "should have a stylesheet processing instruction in the second line of the response" do
        lines = last_response.body.split(/[\r\n]+/)
        lines[1].should == '<?xml-stylesheet type="text/xsl" href="/rdfxml.xsl"?>'
      end

      it "should contain the URI of the document we requested" do
        last_response.body.should =~ %r[<foaf:Document rdf:about="http://example.org/things/934787">]
      end
    end

    context "as an RDF/XML document by suffix" do
      before :each do
        header "Accept", "text/plain"
        get '/things/934787.rdf'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type application/rdf+xml" do
        last_response.content_type.should == 'application/rdf+xml'
      end

      it "should contain the URI of the document we requested" do
        last_response.body.should =~ %r[<foaf:Document rdf:about="http://example.org/things/934787.rdf">]
      end
    end

    context "as a TriX document" do
      before :each do
        get '/things/934787.trix'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type application/trix" do
        last_response.content_type.should == 'application/trix'
      end

      it "should contain the URI of the document we requested" do
        last_response.body.should =~ %r[<uri>http://example.org/things/934787.trix</uri>]
      end
    end

    context "as an unsupport format" do
      before :each do
        get '/things/934787.ratrat'
      end

      it "should return a 400 error" do
        last_response.should be_client_error
      end

      it "should include the text 'Unsupported format' in the body" do
        last_response.body.should =~ /Unsupported format/i
      end
    end
  end

  context "GETing a thing with an alternate display title" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=21492980&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-21492980.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, %r[http://www.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-21492980.json'),
        :content_type => 'application/json'
      )
    end

    context "as an HTML document" do
      before :each do
        get '/things/21492980'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should have the alternate title in the <title> element" do
        last_response.body.should =~ %r|<title>dbpedia lite - iMac</title>|
      end
    end
  end

  context "GETing an HTML thing page that redirects" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=440555&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-440555.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&prop=info&redirects=1&titles=Bovine%20spongiform%20encephalopathy',
        :body => fixture_data('pageinfo-bse.json'),
        :content_type => 'application/json'
      )
      get '/things/440555'
    end

    it "should return a redirect status" do
      last_response.should be_redirect
    end

    it "should set the location header to redirect to /" do
      last_response.location.should == 'http://example.org/things/19344418'
    end
  end

  context "GETing an HTML thing page for a thing that doesn't exist" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=504825766&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-504825766.json'),
        :content_type => 'application/json'
      )
      get '/things/504825766'
    end

    it "should return 404 Not Found" do
      last_response.should be_not_found
    end

    it "should include the text 'Thing not found' in the body" do
      last_response.body.should =~ /Thing not found/i
    end
  end

  context "GETing an HTML thing for something that doesn't exist in Freebase" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=2008435&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-2008435.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, %r[http://www.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-notfound.json'),
        :content_type => 'application/json'
      )
      @stderr_buffer = StringIO.new
      previous_stderr, $stderr = $stderr, @stderr_buffer
      get '/things/2008435'
      $stderr = previous_stderr
    end

    it "should be successful" do
      last_response.should be_ok
    end

    it "should have the correct title in the <title> element" do
      last_response.body.should =~ %r|<title>dbpedia lite - IMAC</title>|
    end

    it "should not contain a link to FreeBase" do
      last_response.body.should_not =~ %r|rdf\.freebase\.com|
    end

    it "should write an error message to stderr" do
      @stderr_buffer.string.should == "Error while reading from Freebase: Freebase query failed return no results\n"
    end
  end

  context "GETing a category" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&pageids=4309010&prop=info&redirects=1',
        :body => fixture_data('pageinfo-4309010.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&gcmlimit=500&gcmnamespace=0%7C14&gcmpageid=4309010&generator=categorymembers&inprop=displaytitle&prop=info',
        :body => fixture_data('categorymembers-4309010.json'),
        :content_type => 'application/json'
      )
    end

    context "as an HTML document" do
      before :each do
        get '/categories/4309010'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type text/html" do
        last_response.content_type.should == 'text/html;charset=utf-8'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "as a N-Triples document" do
      before :each do
        get '/categories/4309010.nt'
      end

      it "should be successful" do
        last_response.should be_ok
      end

      it "should be of type text/html" do
        last_response.content_type.should == 'text/plain;charset=utf-8'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end

      it "should have a triple for the name of the category" do
        last_response.body.should =~ %r|<http://dbpedialite.org/categories/4309010#id> <http://www.w3.org/2000/01/rdf-schema#label> "Villages in Fife" \.|
      end

      it "should have a triple for Ceres being in the category" do
        last_response.body.should =~ %r|<http://dbpedialite.org/things/934787#id> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://dbpedialite.org/categories/4309010#id> \.|
      end
    end
  end

  context "GETing the gems information page" do
    before :each do
      get '/gems'
    end

    it "should be successful" do
      last_response.should be_ok
    end

    it "should be of type text/html" do
      last_response.content_type.should == 'text/html;charset=utf-8'
    end

    it "should include a summary for the Sinatra gem" do
      last_response.body.should =~ /Classy web-development dressed in a DSL/
    end
  end

  context "flipping between pages" do
    context "flipping from a wikipedia page" do
      before :each do
        FakeWeb.register_uri(
          :get, %r[http://en.wikipedia.org/w/api.php],
          :body => fixture_data('pageinfo-rat.json'),
          :content_type => 'application/json'
        )
        get '/flipr?url=http%3A%2F%2Fen.wikipedia.org%2Fwiki%2FRat'
      end

      it "should redirect to the coresponding dbpedia lite page" do
        last_response.status.should == 301
        last_response.location.should == 'http://example.org/things/26471'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "flipping from a dbpedia lite thing page" do
      before :each do
        FakeWeb.register_uri(
          :get, %r[http://en.wikipedia.org/w/api.php],
          :body => fixture_data('pageinfo-rat.json'),
          :content_type => 'application/json'
        )
        get '/flipr?url=http%3A%2F%2Fdbpedialite.org%3A9393%2Fthings%2F52780'
      end

      it "should redirect to the coresponding wikipedia page" do
        last_response.status.should == 301
        last_response.location.should == 'http://en.wikipedia.org/wiki/Rat'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "flipping from a dbpedia lite category page" do
      before :each do
        FakeWeb.register_uri(
          :get, %r[http://en.wikipedia.org/w/api.php],
          :body => fixture_data('pageinfo-villagesinfife.json'),
          :content_type => 'application/json'
        )
        get '/flipr?url=http%3A%2F%2Fdbpedialite.org%3A9393%2Fthings%2F4309010'
      end

      it "should redirect to the coresponding wikipedia page" do
        last_response.status.should == 301
        last_response.location.should == 'http://en.wikipedia.org/wiki/Category:Villages_in_Fife'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "flipping from a dbpedia page" do
      before :each do
        FakeWeb.register_uri(
          :get, %r[http://en.wikipedia.org/w/api.php],
          :body => fixture_data('pageinfo-rat.json'),
          :content_type => 'application/json'
        )
        get '/flipr?url=http%3A%2F%2Fdbpedia.org%2Fpage%2FRat'
      end

      it "should redirect to the coresponding wikipedia page" do
        last_response.status.should == 301
        last_response.location.should == 'http://example.org/things/26471'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "flipping from a Freebase page" do
      before :each do
        FakeWeb.register_uri(
          :get, %r[http://www.freebase.com/api/service/mqlread],
          :body => fixture_data('freebase-mqlread-en-new-york.json'),
          :content_type => 'application/json'
        )
        get '/flipr?url=http%3A%2F%2Fwww.freebase.com%2Fview%2Fen%2Fnew_york'
      end

      it "should redirect to the coresponding Dbpedia lite thing page" do
        last_response.status.should == 301
        last_response.location.should == 'http://example.org/things/645042'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "flipping from an unknown page" do
      before :each do
        get '/flipr?url=http%3A%2F%2Fwww.bbc.co.uk%2F'
      end

      it "should display an error message" do
        last_response.body.should =~ %r{Sorry but I don't know how to flip from: http://www.bbc.co.uk/}
      end
    end
  end

  def rdfa_graph
    base_uri = "http://dbpedialite.org#{last_request.path}"
    RDF::Graph.new(base_uri) do |graph|
      RDF::Reader::for(:rdfa).new(last_response.body, :base_uri => base_uri) do |reader|
        reader.each_statement do |statement|
          graph << statement
        end
      end
    end
  end
end
