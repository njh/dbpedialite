require 'spec_helper'
require 'freebase_api'

describe FreebaseApi do
  context "looking up the Freebase MID for a Wikipedia Pageid" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://api.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-934787.json')
      )
      @data = FreebaseApi.lookup_wikipedia_pageid(934787)
    end

    it "should return a Hash" do
      @data.should be_a(Hash)
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
  end

  context "looking up the Wikipedia Pageid for a Freebase identifier" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://api.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-en-new-york.json')
      )
      @data = FreebaseApi.lookup_by_id('/en/new_york')
    end

    it "should return a Hash" do
      @data.should be_a(Hash)
    end

    it "should return the name of the topic" do
      @data['name'].should == 'New York City'
    end

    it "should return the GUID for the topic" do
      @data['guid'].should == '#9202a8c04000641f80000000002f8906'
    end

    it "should return the Machine ID for the topic" do
      @data['mid'].should == '/m/02_286'
    end

    it "should return the Freebase ID for the topic" do
      @data['id'].should == '/en/new_york'
    end

    it "should have a key for the English Wikipedia page id" do
      @data['key']['namespace'].should == '/wikipedia/en_id'
    end

    it "should return the Wikipedia page id" do
      @data['key']['value'].should == '645042'
    end
  end

  context "lookup up a Wikipedia pageid that doesn't exist in Freebase" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://api.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-notfound.json')
      )
    end

    it "should throw an exception" do
      lambda do
        FreebaseApi.lookup_wikipedia_pageid(4309010)
      end.should raise_error(FreebaseApi::NotFound, 'Freebase query failed return no results')
    end
  end

  context "making an invalid mqlread query" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://api.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-invalid.json')
      )
    end

    it "should throw an exception" do
      lambda do
        FreebaseApi.mqlread(:foo => :bar)
      end.should raise_error(FreebaseApi::Exception, 'Freebase query failed: Type /type/object does not have property foo')
    end
  end

end
