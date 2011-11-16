require 'spec_helper'
require 'wikipedia_api'

describe WikipediaApi do
  context "escaping a page title" do
    it "should convert 'AC/DC' to 'AC/DC'" do
      WikipediaApi.escape_title('AC/DC').should == 'AC/DC'
    end

    it "should convert 'Category:Villages in Fife' to 'Category:Villages_in_Fife'" do
      WikipediaApi.escape_title('Category:Villages in Fife').should == 'Category:Villages_in_Fife'
    end

    it "should convert 'Who Censored Roger Rabbit?' to 'Who_Censored_Roger_Rabbit%3F'" do
      WikipediaApi.escape_title('Who Censored Roger Rabbit?').should == 'Who_Censored_Roger_Rabbit%3F'
    end

    it "should convert '100% (song)' to '100%25_(song)'" do
      WikipediaApi.escape_title('100% (song)').should == '100%25_(song)'
    end

    it "should convert 'C#' to 'C%23'" do
      WikipediaApi.escape_title('C#').should == 'C%23'
    end

    it "should convert '2 + 2 = 5' to 'C%23'" do
      WikipediaApi.escape_title('2 + 2 = 5').should == '2_%2B_2_%3D_5'
    end

    it "should convert 'Nat \"King\" Cole' to 'Nat_%22King%22_Cole'" do
      WikipediaApi.escape_title('Nat "King" Cole').should == 'Nat_%22King%22_Cole'
    end
  end

  context "parsing an HTML page" do
    before :each do
      FakeWeb.register_uri(:get,
        'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=934787&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-934787.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.parse(934787)
    end

    it "should return a Hash" do
      @data.should be_a(Hash)
    end

    it "should return the artitle title" do
      @data['title'].should == 'Ceres, Fife'
    end

    it "should return the date it was last updated" do
      @data['updated_at'].to_s.should == '2011-11-04T06:26:16+00:00'
      @data['updated_at'].class.should == DateTime
    end

    it "should return the longitude" do
      @data['longitude'].should == -2.971445
    end

    it "should return the latitude" do
      @data['latitude'].should == 56.29205
    end

    it "should return the artitle abstract" do
      @data['abstract'].should =~ /\ACeres is a village in Fife, Scotland/
    end

    it "should return an array of images" do
      @data['images'].should == [
        'http://upload.wikimedia.org/wikipedia/commons/c/cd/Fife_UK_location_map.svg',
        'http://upload.wikimedia.org/wikipedia/commons/0/04/Ceres%2C_Fife.jpg',
        'http://upload.wikimedia.org/wikipedia/commons/5/5e/The_Green_at_Ceres%2C_Fife.jpg',
        'http://upload.wikimedia.org/wikipedia/commons/1/19/Ceres_Church%2C_Fife_Scotland.jpg',
        'http://upload.wikimedia.org/wikipedia/commons/3/36/The_Provost%2C_Ceres_Fife.jpg',
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
        'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=26471&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-26471.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.parse(26471)
    end

    it "should return a hash" do
      @data.should be_a(Hash)
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
        'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=3354&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-3354.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.parse(3354)
    end

    it "should return the artitle abstract without pronunciation" do
      @data['abstract'].should =~ /\ABerlin is the capital city of Germany/
    end
  end

  context "removing pronunciation from abstracts" do
    it "should remove the pronunciation from the U2 article" do
      WikipediaApi.strip_pronunciation(
        'U2 (IPA: /ˌjuːˈtuː/) are a rock band from Dublin,'
      ).should be_eql(
        'U2 are a rock band from Dublin,'
      )
    end

    it "should remove the pronunciation from the Albert Camus article" do
      WikipediaApi.strip_pronunciation(
        'Albert Camus (IPA: [albɛʁ kamy]) is '
      ).should be_eql(
        'Albert Camus is '
      )
    end

    it "should remove the pronunciation from the Anton Corbijn article" do
      WikipediaApi.strip_pronunciation(
        'Anton Corbijn (pronounced [kɔrˈbɛin]) (born May 20, 1955) '
      ).should be_eql(
        'Anton Corbijn (born May 20, 1955) '
      )
    end

    it "should remove the pronunciation from the Breed 77 article" do
      WikipediaApi.strip_pronunciation(
        'Breed 77 (pronounced "Breed Seven-Seven") is a band whose'
      ).should be_eql(
        'Breed 77 is a band whose'
      )
    end

    it "should remove the pronunciation from the Sara Beth Bareilles article" do
      WikipediaApi.strip_pronunciation(
        'Sara Beth Bareilles (pronounced /bəˈɹɛlɪs/; born December 7, 1979) is an American'
      ).should be_eql(
        'Sara Beth Bareilles (born December 7, 1979) is an American'
      )
    end
  end

  context "parsing a non-existant HTML page" do
    before :each do
      FakeWeb.register_uri(:get,
        'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=504825766&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-504825766.json'),
        :content_type => 'application/json'
      )
    end

    it "should raise an exception" do
      lambda {WikipediaApi.parse(504825766)}.should raise_error(
        WikipediaApi::PageNotFound,
        'There is no page with ID 504825766'
      )
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

  context "getting information about a page title that doesn't exist" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://en.wikipedia.org/w/api.php],
        :body => fixture_data('pageinfo-zsefpfs.json'),
        :content_type => 'application/json'
      )
    end

    it "should trow a PageNotFound exception" do
      lambda { WikipediaApi.page_info(:titles => 'zsefpfs') }.should raise_error(
        WikipediaApi::PageNotFound
      )
    end
  end

  context "a call to Wikipedia API returns something that isn't JSON" do
    before :each do
      FakeWeb.register_uri(:get,
        %r[http://en.wikipedia.org/w/api.php],
        :body => "<h1>There was an error</h1>",
        :content_type => 'text/html'
      )
    end

    it "should raise an exception" do
      expect { WikipediaApi.get('query') }.should raise_error(
        WikipediaApi::Exception,
        'Response from Wikipedia API was not of type application/json.'
      )
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
