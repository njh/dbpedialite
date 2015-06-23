# encoding: utf-8
require 'spec_helper'
require 'wikidata_api'

describe WikidataApi do

  context "getting Wikipedia page title from a Wikidata identifier" do
    before :each do
      FakeWeb.register_uri(
        :get, 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&ids=Q9531&languages=en&props=sitelinks&sites=enwiki',
        :body => fixture_data('wbgetentities-Q9531.json'),
        :content_type => 'application/json'
      )
      @data = WikidataApi.get_sitelink('Q9531')
    end

    it "should return a Hash" do
      @data.should be_a(Hash)
    end

    it "should have the correct site identifier" do
      @data['site'].should == 'enwiki'
    end

    it "should have the correct page title" do
      @data['title'].should == 'BBC'
    end
  end

  context "getting an entity from Wikidata from an Wikipedia page title" do
    before :each do
      FakeWeb.register_uri(
        :get, 'https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&languages=en&props=info%7Caliases%7Clabels%7Cdescriptions&sites=enwiki&titles=Ceres,%20Fife',
        :body => fixture_data('wbgetentities-ceres.json'),
        :content_type => 'application/json'
      )
      @data = WikidataApi.find_by_title('Ceres, Fife')
    end

    it "should return a Hash" do
      @data.should be_a(Hash)
    end

    it "should have the correct title/identifier" do
      @data['title'].should == 'Q33980'
    end

    it "should be of type 'item" do
      @data['type'].should == 'item'
    end

    it "should have an English label" do
      @data['labels']['en']['value'].should == 'Ceres'
    end

    it "should have an English description" do
      @data['descriptions']['en']['value'].should == 'village in Fife, Scotland'
    end
  end

end
