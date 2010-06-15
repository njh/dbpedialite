require File.dirname(__FILE__) + "/spec_helper.rb"
require 'wikipedia_api'

describe WikipediaApi do

  context "parsing an HTML page" do
    before :each do
      mock_http('en.wikipedia.org', 'ceres.html')
      @data = WikipediaApi.parse(934787)
    end

    it "should return valid == true" do
      @data['valid'].should be_true
    end

    it "should return the artitle title" do
      @data['title'].should == 'Ceres, Fife'
    end

    it "should return the date it was last updated" do
      @data['updated_at'].to_s.should == '2010-04-29T10:22:00+00:00'
      @data['updated_at'].class.should == DateTime
    end

    it "should return the longitude" do
      @data['longitude'].should == -2.970134
    end

    it "should return the latitude" do
      @data['latitude'].should == 56.293431
    end

    it "should return the artitle abstract" do
      @data['abstract'].should =~ /\ACeres is a village in Fife, Scotland/
    end

    it "should return an array of categories" do
      @data['categories'].should == ['Category:Villages in Fife', 'Category:Churches in Fife']
    end
  end

  context "parsing an HTML page with <p> in the infobox" do
    before :each do
      mock_http('en.wikipedia.org', 'rat.html')
      @data = WikipediaApi.parse(26471)
    end

    it "should return valid == true" do
      @data['valid'].should be_true
    end

    it "should return the artitle title" do
      @data['title'].should == 'Rat'
    end

    it "should have no latitude and longitude" do
      @data['latitude'].should be_nil
      @data['longitude'].should be_nil
    end

    it "should return the artitle abstract" do
      @data['abstract'].should =~ /\ARats are various medium-sized, long-tailed rodents of the superfamily Muroidea/
    end

    it "should return an array of categories" do
      @data['categories'].should == [
        "Category:Old World rats and mice",
        "Category:Urban animals",
        "Category:Scavengers",
        "Category:Wikipedia semi-protected pages",
        "Category:Articles with 'species' microformats"
      ]
    end
  end

  context "parsing a non-existant HTML page" do
    before :each do
      mock_http('en.wikipedia.org', 'notfound.html')
      @data = WikipediaApi.parse(504825766)
    end

    it "should return valid == false" do
      @data['valid'].should be_false
    end
  end

  context "querying by title" do
    before :each do
      mock_http('en.wikipedia.org', 'query-u2.json')
      @data = WikipediaApi.query(:titles => 'U2').values.first
    end

    it "should return the title" do
      @data['title'].should == 'U2'
    end

    it "should return the pageid" do
      @data['pageid'].should == 52780
    end

    it "should return the namespace" do
      @data['ns'].should == 0
    end

    it "should return the last modified date" do
      @data['touched'].should == "2010-05-12T22:44:49Z"
    end
  end

  context "searching for Rat" do
    before :each do
      mock_http('en.wikipedia.org', 'search-rat.json')
      @data = WikipediaApi.search('Rat', :srlimit => 20)
    end

    it "the first result should have a title" do
      @data.first['title'].should == 'Rat'
    end

    it "the first result should have a timestamp" do
      @data.first['timestamp'].should == '2010-05-01T09:22:19Z'
    end

    it "the first result should have a namespace" do
      @data.first['ns'].should == 0
    end

    it "the first result should have a snippet" do
      @data.first['snippet'].should =~ /^"True rats" are members of the genus Rattus/
    end
  end

  context "resolving a single title to a pageid" do
    before :each do
      mock_http('en.wikipedia.org', 'query-u2.json')
      @data = WikipediaApi.title_to_pageid('U2')
    end

    it "should return a single result" do
      @data.size.should == 1
    end

    it "should include the title as a key in the result" do
      @data.keys.should include('U2')
    end

    it "should return the right pageid for the title key" do
      @data['U2'].should == 52780
    end
  end

  context "resolving multiple titles to pageids" do
    before :each do
      mock_http('en.wikipedia.org', 'query-villages-churches.json')
      @data = WikipediaApi.title_to_pageid(['Category:Villages in Fife','Category:Churches in Fife'])
    end

    it "should return two results" do
      @data.size.should == 2
    end

    it "should include the first title as a key in the result" do
      @data.keys.should include('Category:Villages in Fife')
    end

    it "should return the right pageid for the first title" do
      @data['Category:Villages in Fife'].should == 4309010
    end

    it "should include the second title as a key in the result" do
      @data.keys.should include('Category:Churches in Fife')
    end

    it "should return the right pageid for the second title" do
      @data['Category:Churches in Fife'].should == 8528555
    end
  end

end
