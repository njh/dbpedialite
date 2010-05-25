require File.dirname(__FILE__) + "/spec_helper.rb"
require 'dbpedialite'

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

    it "should be text/html" do
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

end
