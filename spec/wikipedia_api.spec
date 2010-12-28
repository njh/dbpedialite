require File.dirname(__FILE__) + "/spec_helper.rb"
require 'wikipedia_api'

describe WikipediaApi do
  context "parsing an HTML page" do
    before :each do
      FakeWeb.register_uri(:get,
        'http://en.wikipedia.org/wiki/index.php?curid=934787',
        :body => fixture_data('ceres.html'),
        :content_type => 'text/html; charset=UTF-8'
      )
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

    it "should return an array of images" do
      @data['images'].should == [
        'http://upload.wikimedia.org/wikipedia/commons/d/d6/Scottish_infobox_template_map.png',
        'http://upload.wikimedia.org/wikipedia/commons/0/04/Ceres%2C_Fife.jpg'
      ]
    end

    it "should return an array of external links" do
      @data['externallinks'].should == [
        'http://www.fife.50megs.com/ceres-history.htm'
      ]
    end
  end

  context "parsing an HTML page with <p> in the infobox" do
    before :each do
      FakeWeb.register_uri(:get,
        'http://en.wikipedia.org/wiki/index.php?curid=26471',
        :body => fixture_data('rat.html'),
        :content_type => 'text/html; charset=UTF-8'
      )
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
  end

  context "parsing an HTML page with pronunciation details in the abstract" do
    before :each do
      FakeWeb.register_uri(:get,
        'http://en.wikipedia.org/wiki/index.php?curid=3354',
        :body => fixture_data('berlin.html'),
        :content_type => 'text/html; charset=UTF-8'
      )
      @data = WikipediaApi.parse(3354)
    end

    it "should return the artitle abstract without pronunciation" do
      @data['abstract'].should =~ /\ABerlin is the capital city of Germany/
    end
  end

  context "parsing a non-existant HTML page" do
    before :each do
      FakeWeb.register_uri(:get,
        'http://en.wikipedia.org/wiki/index.php?curid=504825766',
        :body => fixture_data('notfound.html'),
        :content_type => 'text/html; charset=UTF-8'
      )
      @data = WikipediaApi.parse(504825766)
    end

    it "should return valid == false" do
      @data['valid'].should be_false
    end
  end

  context "getting information about a page by title" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('pageinfo-u2.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.page_info(:titles => 'U2')
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

  context "getting information about a page by pageid" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('pageinfo-4309010.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.page_info(:pageids => '4309010')
    end

    it "should return the title" do
      @data['title'].should == 'Category:Villages in Fife'
    end

    it "should return the pageid" do
      @data['pageid'].should == 4309010
    end

    it "should return the namespace" do
      @data['ns'].should == 14
    end

    it "should return the last modified date" do
      @data['touched'].should == "2010-11-04T04:11:11Z"
    end
  end

  context "getting information about a page that doesn't exist" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('pageinfo-zsefpfs.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.page_info(:titles => 'zsefpfs')
    end

    it "should return nil" do
      @data.should be_nil
    end
  end

  context "searching for Rat" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('search-rat.json'),
        :content_type => 'application/json'
      )
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

  context "getting the members of a category" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('categorymembers-villages.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.category_members('Category:Villages in Fife')
      @data.sort! {|a,b| a['pageid'] <=> b['pageid']}
    end

    it "should return eighty results" do
      @data.size.should == 80
    end

    it "should return a title for the first result" do
      @data.first['title'].should == 'Aberdour'
    end

    it "should return a pageid for the first result" do
      @data.first['pageid'].should == 2712
    end

    it "should return a namespace for the first result" do
      @data.first['ns'].should == 0
    end
  end

  context "getting the categories that something is a member of" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('categories-934787.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.page_categories(934787)
      @data.sort! {|a,b| a['pageid'] <=> b['pageid']}
    end

    it "should return 3 results" do
      @data.size.should == 3
    end

    it "should return a title for the first result" do
      @data.first['title'].should == 'Category:Villages in Fife'
    end

    it "should return a pageid for the first result" do
      @data.first['pageid'].should == 4309010
    end

    it "should return a namespace for the first result" do
      @data.first['ns'].should == 14
    end
  end
end
