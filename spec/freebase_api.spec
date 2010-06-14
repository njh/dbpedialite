require File.dirname(__FILE__) + "/spec_helper.rb"
require 'freebase_api'

describe FreebaseApi do

  context "looking up the Freebase MID for a Wikipedia Pageid" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('freebase-mqlread-ceres.json')
      )
      Net::HTTP.expects(:start).once.returns(response)
      @data = FreebaseApi.lookup_wikipedia_pageid(934787)
    end

    it "should not return nil" do
      @data.should_not be_nil
    end
    
    it "should return the name of the topic" do
      @data['name'].should == 'Ceres'
    end
    
    it "should return the GUID for the topic" do
      @data['guid'].should == '#9202a8c04000641f80000000003bb45c'
    end
    
    it "should return the Machine ID for the topic" do
      @data['mid'].should == '/m/03rf2x'
    end
    
    it "should return the Freebase ID for the topic" do
      @data['id'].should == '/en/ceres_united_kingdom'
    end
    
    it "should construct an RDF URI based on the Machine ID" do
      @data['rdf_uri'].to_s.should == 'http://rdf.freebase.com/ns/m.03rf2x'
    end
  end

end
