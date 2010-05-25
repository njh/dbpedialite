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

end
