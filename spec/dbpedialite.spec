require File.dirname(__FILE__) + "/spec_helper.rb"
require 'dbpedialite'
require 'rack/test'

## Note: these are integration tests. Mocking is done at the HTTP request level.

set :environment, :test

describe 'dbpedia lite' do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  context "GETing the homepage" do
    before :each do
      get '/'
    end

    it "should be successful" do
      last_response.should be_ok
    end

    it "should be of type text/html" do
      last_response.content_type.should == 'text/html'
    end

    it "should be cachable" do
      last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
    end

    it "should contain the readme text" do
      last_response.body.should =~ /takes some of the structured data/
    end
  end

  context "GETing a search page with a query string" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('search-rat.json')
      )
      Net::HTTP.expects(:start).once.returns(response)
      get '/search?q=rat'
    end

    it "should be successful" do
      last_response.should be_ok
    end

    it "should be text/html" do
      last_response.content_type.should == 'text/html'
    end

    it "should contain an escaped link to a title page" do
      last_response.body.should =~ %r[<a href=\"/titles/Brown_rat\">Brown rat</a>]
    end

    it "should contain snippets" do
      last_response.body.should =~ %r[The brown <span class='searchmatch'>rat</span>]
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
      last_response.location.should == '/'
    end
  end

  context "GETing a title URL" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('query-u2.json')
      )
      Net::HTTP.expects(:start).once.returns(response)
      get '/titles/U2'
    end

    it "should be a redirect" do
      last_response.should be_redirect
    end

    it "should set the location header to redirect to /" do
      last_response.location.should == '/things/52780'
    end

    it "should be cachable" do
      last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
    end
  end

  context "GETing an invalid title URL" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('query-zsefpfs.json')
      )
      Net::HTTP.expects(:start).once.returns(response)
      get '/titles/zsefpfs'
    end

    it "should return 404 Not Found" do
      last_response.should be_not_found
    end
  end

  context "GETing an HTML page for a geographic thing" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('ceres.html')
      )
      Net::HTTP.expects(:start).once.returns(response)
      header "Accept", "text/html"
      get '/things/934787'
    end

    it "should be successful" do
      last_response.should be_ok
    end

    it "should be of type text/html" do
      last_response.content_type.should == 'text/html'
    end

    it "should be cachable" do
      last_response.headers['Cache-Control'].should =~ /max-age=([1-9]+)/
    end

    it "should be contain an abstract for the thing" do
      last_response.body.should =~ /Ceres is a village in Fife, Scotland/
    end

    it "should have a Google Map on the page" do
      last_response.body.should =~ %r[<div id="map"></div>]
    end

    it "should have the title of the thing as RDFa"

  end

  context "GETing an HTML thing page for a thing that doesn't exist" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('notfound.html')
      )
      Net::HTTP.expects(:start).once.returns(response)
      get '/things/504825766'
    end

    it "should return 404 Not Found" do
      last_response.should be_not_found
    end

    it "should include the text 'Thing Not Found' in the body" do
      last_response.body.should =~ /Thing Not Found/i
    end
  end

  context "GETing an unsupport format for a thing" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('ceres.html')
      )
      Net::HTTP.expects(:start).once.returns(response)
      get '/things/934787.ratrat'
    end

    it "should return a 400 error" do
      last_response.should be_client_error
    end

    it "should include the text 'Unsupported format' in the body" do
      last_response.body.should =~ /Unsupported format/i
    end
  end

  context "extracting vocabularies" do
    before :each do
      @graph = RDF::Graph.new do |g|
        g << [RDF::URI('http://a.com/'), RDF::DC.title, "A"]
        g << [RDF::URI('http://b.com/'), RDF::FOAF.name, "B"]
        g << [RDF::URI('http://c.com/'), RDF::FOAF.nick, "C"]
      end
      @vocabularies = extract_vocabularies(@graph)
    end

    it "should extract 2 vocabularies" do
      @vocabularies.length.should == 2
    end

    it "should have a key for the FOAF vocabulary" do
      @vocabularies.should have_key :foaf
    end

    it "should have a key for the FOAF vocabulary" do
      @vocabularies.should have_key :foaf
    end

    it "should havw the right namespace the FOAF vocabulary" do
      @vocabularies[:foaf].should == RDF::FOAF
    end

    it "should havw the right namespace the DC vocabulary" do
      @vocabularies[:dc].should == RDF::DC
    end
  end
end
