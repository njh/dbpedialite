require File.dirname(__FILE__) + "/spec_helper.rb"
require 'wikipedia_api'

describe WikipediaApi do

  context "paring an HTML page" do
    before :each do
      response = mock(
        :value => nil,
        :body => fixture_data('ceres.html')
      )
      Net::HTTP.expects(:start).once.returns(response)
      @data = WikipediaApi.parse(934787)
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

end
