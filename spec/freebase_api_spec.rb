require 'spec_helper'
require 'freebase_api'

describe FreebaseApi do
  context "looking up the Freebase MID for a Wikipedia Pageid" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://www.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-ceres.json')
      )
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
  end

  context "lookup up a Wikipedia pageid that doesn't exist in Freebase" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://www.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-notfound.json')
      )
    end

    it "should throw an exception" do
      lambda do
        FreebaseApi.lookup_wikipedia_pageid(4309010)
      end.should raise_error(RuntimeError, 'Failed to lookup wikipedia page id')
    end
  end

  context "making an invalid mqlread query" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://www.freebase.com/api/service/mqlread],
        :body => fixture_data('freebase-mqlread-invalid.json')
      )
    end

    it "should throw an exception" do
      lambda do
        FreebaseApi.mqlread(:foo => :bar)
      end.should raise_error(RuntimeError, 'Freebase query failed: Type /type/object does not have property foo')
    end
  end

end
