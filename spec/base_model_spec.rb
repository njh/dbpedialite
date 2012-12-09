require 'spec_helper'
require 'base_model'

describe BaseModel do

  context "creating an object from a pageid as the first parameter" do
    before :each do
      @obj = BaseModel.new('52780')
    end

    it "should respond to 'pageid' with its pageid" do
      @obj.pageid.should == '52780'
    end

    it "should respond to 'uri' with an example URI" do
      @obj.uri.should == RDF::URI('http://dbpedialite.org/base/52780#id')
    end

    it "should respond to 'doc_uri' with an example URI for the document" do
      @obj.doc_uri.should == RDF::URI('http://dbpedialite.org/base/52780')
    end

    it "should respond to 'doc_path' with a path for the default format" do
      @obj.doc_path.should == RDF::URI('/base/52780')
    end

    it "should respond to 'doc_path(:json)' with a path for the JSON format" do
      @obj.doc_path(:json).should == RDF::URI('/base/52780.json')
    end

    it "should respond to 'doc_path(:xml)' with a path for the XML format" do
      @obj.doc_path(:xml).should == RDF::URI('/base/52780.xml')
    end

  end

  context "creating an object from a hash" do
    before :each do
      @obj = BaseModel.new(:pageid => '934787', :ns => 0, :title => 'Ceres, Fife')
    end

    it "should respond to 'pageid' with its pageid" do
      @obj.pageid.should == '934787'
    end

    it "should respond to 'title' with its title" do
      @obj.title.should == 'Ceres, Fife'
    end

    it "should respond to 'wikipedia_uri' with the Wikipedia URI" do
      @obj.wikipedia_uri.should == RDF::URI('http://en.wikipedia.org/wiki/Ceres,_Fife')
    end

    it "should respond to 'dbpedia_uri' with the dbpedia URI" do
      @obj.dbpedia_uri.should == RDF::URI('http://dbpedia.org/resource/Ceres,_Fife')
    end
  end

  context "creating an object with brackets in the title" do
    before :each do
      @obj = BaseModel.new(:pageid => '192584', :ns => 0, :title => 'Keith Allen (actor)')
    end

    it "should respond to 'pageid' with its pageid" do
      @obj.pageid.should == '192584'
    end

    it "should respond to 'title' with its title" do
      @obj.title.should == 'Keith Allen (actor)'
    end

    it "should respond to 'wikipedia_uri' with the Wikipedia URI" do
      @obj.wikipedia_uri.should == RDF::URI('http://en.wikipedia.org/wiki/Keith_Allen_(actor)')
    end

    it "should respond to 'dbpedia_uri' with the dbpedia URI" do
      @obj.dbpedia_uri.should == RDF::URI('http://dbpedia.org/resource/Keith_Allen_%28actor%29')
    end
  end

  context "updating an object with a hash" do
    before :each do
      @obj = BaseModel.new(934787)
      @obj.update(:pageid => 1234, :ns => 0, :title => 'New')
    end

    it "should respond return the new value for the pageid" do
      @obj.pageid.should == 1234
    end

    it "should respond return the new value for the title" do
      @obj.title.should == 'New'
    end
  end

end
