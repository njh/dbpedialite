# encoding: utf-8

require 'spec_helper'
require 'dbpedialite'


## Note: these are integration tests. Mocking is done using FakeWeb.

describe 'dbpedia lite' do
  include Rack::Test::Methods

  def app
    DbpediaLite
  end

  before :each do
    app.enable :raise_errors
    app.disable :show_exceptions
    app.set :environment, :test
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

      it "should have CORS enabled" do
        last_response.headers['Access-Control-Allow-Origin'].should == '*'
      end

      it "should contain the readme text" do
        last_response.body.should =~ /take some of the structured data/
      end

      it "should contain the bookmarklet" do
        last_response.body.should =~ %r|javascript:location.href='http://example.org/flipr\?url=|
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "in a production environment" do
      before :each do
        app.set :environment, :production
        get '/'
      end

      it "should redirect" do
        last_response.status.should == 301
        last_response.location.should == 'http://www.dbpedialite.org/'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end
  end

  context "GETing a search page with a query string" do
    before :each do
      FakeWeb.register_uri(
        :get, %r[https://en.wikipedia.org/w/api.php],
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
        :get, %r[https://en.wikipedia.org/w/api.php],
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

    it "should be cachable" do
      last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
    end
  end

  context "GETing the search page for unsupport format" do
    before :each do
      FakeWeb.register_uri(
        :get, %r[https://en.wikipedia.org/w/api.php],
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
        :get, %r[https://en.wikipedia.org/w/api.php],
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
        :get, 'https://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&prop=info&redirects=1&titles=Category:Villages_in_Fife',
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
        :get, %r[https://en.wikipedia.org/w/api.php],
        :body => fixture_data('pageinfo-zsefpfs.json'),
        :content_type => 'application/json'
      )
      get '/titles/zsefpfs'
    end

    it "should return 404 Not Found" do
      last_response.should be_not_found
    end

    it "should be cachable" do
      last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
    end
  end

  context "GETing a title that isn't a thing" do
    before :each do
      FakeWeb.register_uri(
        :get, %r[https://en.wikipedia.org/w/api.php],
        :body => fixture_data('pageinfo-user.json'),
        :content_type => 'application/json'
      )
      get '/titles/User:Nhumfrey'
    end

    it "should be an error" do
      last_response.should be_client_error
    end

    it "should inform the user that the namespace isn't supported" do
      last_response.body.should =~ /Unsupported Wikipedia namespace/
    end

    it "should be cachable" do
      last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
    end
  end

  context "GETing a geographic thing" do
    before :each do
      FakeWeb.register_uri(
        :get, 'https://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&pageids=934787&prop=info&redirects=1',
        :body => fixture_data('pageinfo-934787.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&languages=en&props=info%7Caliases%7Clabels%7Cdescriptions&sites=enwiki&titles=Ceres,%20Fife',
        :body => fixture_data('wbgetentities-ceres.json'),
        :content_type => 'application/json'
      )
    end

    context "as an HTML document using content negotiation" do
      before :each do
        header "Accept", "text/html"
        get '/things/934787'
      end

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q33980" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q33980'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end


    context "as an N-Triples document" do
      before :each do
        FakeWeb.register_uri(
          :get, 'https://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=934787&prop=text',
          :body => fixture_data('parse-934787.json'),
          :content_type => 'application/json'
        )
        header "Accept", "text/plain"
        get '/things/934787'
      end

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q33980" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q33980'
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

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q33980" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q33980'
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

      it "should be redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q33980" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q33980'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "as an RDF/XML document by content negotiation" do
      before :each do
        header "Accept", "application/rdf+xml"
        get '/things/934787'
      end

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q33980" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q33980'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "as an RDF/XML document by suffix" do
      before :each do
        header "Accept", "text/plain"
        get '/things/934787.rdf'
      end

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q33980" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q33980'
      end
    end

    context "as a TriX document" do
      before :each do
        get '/things/934787.trix'
      end

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q33980" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q33980'
      end
    end

    context "as a JSON-LD document" do
      before :each do
        get '/things/934787.jsonld'
      end

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q33980" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q33980'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "as an unsupport format" do
      before :each do
        get '/things/934787.ratrat'
      end

      it "should return be a reidrect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q33980" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q33980'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end
  end

  context "GETing a thing with an alternate display title" do
    before :each do
      FakeWeb.register_uri(
        :get, 'https://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&pageids=21492980&prop=info&redirects=1',
        :body => fixture_data('pageinfo-21492980.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&languages=en&props=info%7Caliases%7Clabels%7Cdescriptions&sites=enwiki&titles=IMac',
        :body => fixture_data('wbgetentities-imac.json'),
        :content_type => 'application/json'
      )
    end

    context "as an HTML document" do
      before :each do
        get '/things/21492980'
      end

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q14091" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q14091'
      end
    end
  end

  context "GETing an HTML thing page that redirects" do
    before :each do
      FakeWeb.register_uri(
        :get, 'https://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&pageids=440555&prop=info&redirects=1',
        :body => fixture_data('pageinfo-440555.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&languages=en&props=info%7Caliases%7Clabels%7Cdescriptions&sites=enwiki&titles=Bovine%20spongiform%20encephalopathy',
        :body => fixture_data('wbgetentities-bse.json'),
        :content_type => 'application/json'
      )
      get '/things/440555'
    end

    it "should return a redirect" do
      last_response.should be_redirect
    end

    it "should set the location header to redirect to /" do
      last_response.location.should == 'http://www.wikidata.org/entity/Q154666'
    end
  end

  context "GETing an HTML thing page for a thing that doesn't exist" do
    before :each do
      FakeWeb.register_uri(
        :get, 'https://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&pageids=504825766&prop=info&redirects=1',
        :body => fixture_data('pageinfo-504825766.json'),
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

    it "should be cachable" do
      last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
    end
  end

  context "GETing an HTML thing for something that doesn't exist in Wikidata" do
    before :each do
      FakeWeb.register_uri(
        :get, 'https://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&pageids=2008435&prop=info&redirects=1',
        :body => fixture_data('pageinfo-2008435.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&languages=en&props=info%7Caliases%7Clabels%7Cdescriptions&sites=enwiki&titles=IMAC',
        :body => fixture_data('wbgetentities-notfound.json'),
        :content_type => 'application/json'
      )
      @stderr_buffer = StringIO.new
      previous_stderr, $stderr = $stderr, @stderr_buffer
      get '/things/2008435'
      $stderr = previous_stderr
    end

    it "should be a not found page" do
      last_response.should be_not_found
    end

    it "should write an error message to stderr" do
      @stderr_buffer.string.should == "Error while reading from Wikidata: Failed to lookup title in Wikidata\n"
    end
  end

  context "GETing a category" do
    before :each do
      FakeWeb.register_uri(
        :get, 'https://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&pageids=4309010&prop=info&redirects=1',
        :body => fixture_data('pageinfo-4309010.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&languages=en&props=info%7Caliases%7Clabels%7Cdescriptions&sites=enwiki&titles=Category:Villages%20in%20Fife',
        :body => fixture_data('wbgetentities-category-villages-in-fife.json'),
        :content_type => 'application/json'
      )
    end

    context "as an HTML document" do
      before :each do
        get '/categories/4309010'
      end

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q8898842" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q8898842'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
      end
    end

    context "as a N-Triples document" do
      before :each do
        get '/categories/4309010.nt'
      end

      it "should be a redirect" do
        last_response.should be_redirect
      end

      it "should redirect to wikidata Q8898842" do
        last_response.location.should == 'http://www.wikidata.org/entity/Q8898842'
      end

      it "should be cachable" do
        last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
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
          :get, %r[https://en.wikipedia.org/w/api.php],
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

    context "flipping from a wikipedia https page" do
      before :each do
        FakeWeb.register_uri(
          :get, %r[https://en.wikipedia.org/w/api.php],
          :body => fixture_data('pageinfo-rat.json'),
          :content_type => 'application/json'
        )
        get '/flipr?url=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FRat'
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
          :get, %r[https://en.wikipedia.org/w/api.php],
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

    context "flipping from a dbpedia lite thing page with a fragment identifier" do
      before :each do
        FakeWeb.register_uri(
          :get, %r[https://en.wikipedia.org/w/api.php],
          :body => fixture_data('pageinfo-rat.json'),
          :content_type => 'application/json'
        )
        get '/flipr?url=http%3A%2F%2Fdbpedialite.org%2Fthings%2F26471%23id'
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
          :get, %r[https://en.wikipedia.org/w/api.php],
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
          :get, %r[https://en.wikipedia.org/w/api.php],
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

    context "flipping from an unknown page" do
      before :each do
        get '/flipr?url=http%3A%2F%2Fwww.bbc.co.uk%2F'
      end

      it "should display an error message" do
        last_response.status.should == 200
        last_response.body.should =~ %r{Sorry but I don't know how to flip from: http://www.bbc.co.uk/}
      end
    end
  end

  def rdfa_graph
    base_uri = "http://www.dbpedialite.org#{last_request.path}"
    RDF::Graph.new(base_uri) do |graph|
      RDF::Reader::for(:rdfa).new(last_response.body, :base_uri => base_uri) do |reader|
        reader.each_statement do |statement|
          graph << statement
        end
      end
    end
  end
end
