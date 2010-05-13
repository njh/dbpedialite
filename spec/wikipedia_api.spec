require File.dirname(__FILE__) + "/spec_helper.rb"
require 'wikipedia_api'

describe WikipediaApi do

  context "parsing an HTML page" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('ceres.html')
      )
      Net::HTTP.expects(:start).once.returns(response)
      @data = WikipediaApi.parse(934787)
    end

    it "should return valid == true" do
      @data['valid'].should be_true
    end

    it "should return the artitle title" do
      @data['title'].should == 'Ceres, Fife'
    end

    it "should return the artitle title" do
      @data['updated_at'].to_s.should == '2010-04-29T10:22:00+00:00'
      @data['updated_at'].class.should == DateTime
    end

    it "should return the artitle title" do
      @data['longitude'].should == -2.970134
    end

    it "should return the artitle title" do
      @data['latitude'].should == 56.293431
    end

    it "should return the artitle title" do
      @data['abstract'].should =~ /Ceres is a village in Fife, Scotland/
    end
  end

  context "parsing a non-existant HTML page" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('notfound.html')
      )
      Net::HTTP.expects(:start).once.returns(response)
      @data = WikipediaApi.parse(504825766)
    end

    it "should return valid == false" do
      @data['valid'].should be_false
    end
  end
  
  context "querying by title" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('query-u2.json')
      )
      Net::HTTP.expects(:start).once.returns(response)
      @data = WikipediaApi.query(:titles => 'U2')
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
      response = mock(
        :value => nil,
        :body => fixture_data('search-rat.json')
      )
      Net::HTTP.expects(:start).once.returns(response)
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

end
