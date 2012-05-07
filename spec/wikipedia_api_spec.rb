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

    it "should not convert '—We Also Walk Dogs' to '—We_Also_Walk_Dogs'" do
      WikipediaApi.escape_title('—We Also Walk Dogs').should == '—We_Also_Walk_Dogs'
    end
  end

  context "escaping a query parameter" do
    it "should convert 'Florence + the Machine' to 'Florence%20%2B%20the%20Machine'" do
      WikipediaApi.escape_query('Florence + the Machine').should == 'Florence%20%2B%20the%20Machine'
    end

    it "should convert 'C#' to 'C%23'" do
      WikipediaApi.escape_query('C#').should == 'C%23'
    end
  end

  context "parsing a page" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=934787&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-934787.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.parse(934787)
    end

    it "should return a Hash" do
      @data.should be_a(Hash)
    end

    it "should return the article's page url title" do
      @data['title'].should == 'Ceres, Fife'
    end

    it "should return the article display title" do
      @data['displaytitle'].should == 'Ceres, Fife'
    end

    it "should return the date it was last updated" do
      @data['updated_at'].to_s.should == '2012-05-05T04:35:21+00:00'
      @data['updated_at'].class.should == DateTime
    end

    it "should return the longitude" do
      @data['longitude'].should == -2.971445
    end

    it "should return the latitude" do
      @data['latitude'].should == 56.29205
    end

    it "should return the article abstract" do
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

  context "parsing a page titled with a lowercase first letter" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=21492980&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-21492980.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.parse(21492980)
    end

    it "should return a hash" do
      @data.should be_a(Hash)
    end

    it "should return the article's page url title" do
      @data['title'].should == 'IMac'
    end

    it "should return the article display title" do
      @data['displaytitle'].should == 'iMac'
    end

    it "should have no latitude and longitude" do
      @data['latitude'].should be_nil
      @data['longitude'].should be_nil
    end

    it "should return the article abstract" do
      @data['abstract'].should =~ /^The iMac is a range of all-in-one Macintosh desktop computers built by Apple Inc\./
    end
  end

  context "parsing a page with <p> in the infobox" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=26471&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-26471.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.parse(26471)
    end

    it "should return a hash" do
      @data.should be_a(Hash)
    end

    it "should return the article's page url title" do
      @data['title'].should == 'Rat'
    end

    it "should return the article display title" do
      @data['displaytitle'].should == 'Rat'
    end

    it "should have no latitude and longitude" do
      @data['latitude'].should be_nil
      @data['longitude'].should be_nil
    end

    it "should return the article abstract" do
      @data['abstract'].should =~ /\ARats are various medium-sized, long-tailed rodents of the superfamily Muroidea/
    end
  end

  context "parsing a page with multiple paragraphs" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=18624945&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-18624945.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.parse(18624945)
    end

    it "should return a hash" do
      @data.should be_a(Hash)
    end

    it "should return the article's page url title" do
      @data['title'].should == 'True Blood'
    end

    it "should return the article display title without HTML" do
      @data['displaytitle'].should == 'True Blood'
    end

    it "should contain an the first paragraph of the abastract" do
      @data['abstract'].should =~ %r[^True Blood is an American television series created and produced by Alan Ball]
    end

    it "should contain the end of the second paragraph of the abastract" do
      @data['abstract'].should =~ %r[been renewed for a fifth season of 12 episodes to air on June 10, 2012\.$]
    end
  end

  context "parsing a page with pronunciation details in the abstract" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=3354&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-3354.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.parse(3354)
    end

    it "should return the article abstract without pronunciation" do
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

  context "parsing a page with an edit link in the page" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=32838&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-32838.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.parse(32838)
    end

    it "should have a page url title" do
      @data['title'].should == 'Vincent Ward'
    end

    it "should have a display title" do
      @data['displaytitle'].should == 'Vincent Ward'
    end

    it "should pull out the correct abstract" do
      @data['abstract'].should == 'Vincent Ward, ONZM (born 16 February 1956) is a film director and screenwriter.'
    end

    it "should have an array of external links" do
      @data['externallinks'].should == [
        'http://www.imdb.com/name/nm0911910/'
      ]
    end
  end

  context "parsing a redirect page" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=440555&prop=text%7Cdisplaytitle',
        :body => fixture_data('parse-440555.json'),
        :content_type => 'application/json'
      )
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&prop=info&redirects=1&titles=Bovine%20spongiform%20encephalopathy',
        :body => fixture_data('pageinfo-bse.json'),
        :content_type => 'application/json'
      )
    end

    it "should raise a Redirect exception" do
      lambda {WikipediaApi.parse(440555)}.should raise_error(
        WikipediaApi::Redirect
      )
    end
  end

  context "parsing a non-existant page" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=504825766&prop=text%7Cdisplaytitle',
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
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&prop=info&redirects=1&titles=U2',
        :body => fixture_data('pageinfo-u2.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.page_info(:titles => 'U2')
    end

    it "should return the article's page url title" do
      @data['title'].should == 'U2'
    end

    it "should return the article display title" do
      @data['displaytitle'].should == 'U2'
    end

    it "should return the pageid" do
      @data['pageid'].should == 52780
    end

    it "should return the namespace" do
      @data['ns'].should == 0
    end

    it "should return the last modified date" do
      @data['touched'].should == "2012-05-07T12:24:23Z"
    end
  end

  context "getting information about a page by pageid" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&pageids=4309010&prop=info&redirects=1',
        :body => fixture_data('pageinfo-4309010.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.page_info(:pageids => '4309010')
    end

    it "should return the page url title" do
      @data['title'].should == 'Category:Villages in Fife'
    end

    it "should return the display title" do
      @data['displaytitle'].should == 'Category:Villages in Fife'
    end

    it "should return the pageid" do
      @data['pageid'].should == 4309010
    end

    it "should return the namespace" do
      @data['ns'].should == 14
    end

    it "should return the last modified date" do
      @data['touched'].should == "2012-05-07T12:15:28Z"
    end
  end

  context "getting information about a page with HTML in the display title" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&pageids=18624945&prop=info&redirects=1',
        :body => fixture_data('pageinfo-18624945.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.page_info(:pageids => '18624945')
    end

    it "should return the page url title" do
      @data['title'].should == 'True Blood'
    end

    it "should return the display title without HTML" do
      @data['displaytitle'].should == 'True Blood'
    end

    it "should return the pageid" do
      @data['pageid'].should == 18624945
    end

    it "should return the namespace" do
      @data['ns'].should == 0
    end

    it "should return the last modified date" do
      @data['touched'].should == "2012-05-07T13:33:10Z"
    end
  end


  context "getting information about a page title that doesn't exist" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&inprop=displaytitle&prop=info&redirects=1&titles=zsefpfs',
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
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json',
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
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&list=search&srlimit=20&srprop=snippet%7Ctitlesnippet&srsearch=Rat',
        :body => fixture_data('search-rat.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.search('Rat', :srlimit => 20)
    end

    it "the first result should have a title" do
      @data.first['title'].should == 'Rat'
    end

    it "the first result should have a title snippet" do
      @data.first['titlesnippet'].should == "<span class='searchmatch'>Rat</span>"
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
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&cmlimit=500&cmprop=ids%7Ctitle&cmsort=sortkey&cmtitle=Category:Villages%20in%20Fife&format=json&list=categorymembers',
        :body => fixture_data('categorymembers-villages.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.category_members('Category:Villages in Fife')
      @data.sort! {|a,b| a['pageid'] <=> b['pageid']}
    end

    it "should return eighty three results" do
      @data.size.should == 83
    end

    it "should return a page url title for the first result" do
      @data.first['title'].should == 'Aberdour'
    end

    # FIXME: work out how to implement this
    it "should return the page display title"

    it "should return a pageid for the first result" do
      @data.first['pageid'].should == 2712
    end

    it "should return a namespace for the first result" do
      @data.first['ns'].should == 0
    end
  end

  context "getting the categories that something is a member of" do
    before :each do
      FakeWeb.register_uri(
        :get, 'http://en.wikipedia.org/w/api.php?action=query&format=json&gcllimit=500&generator=categories&inprop=displaytitle&pageids=934787&prop=info',
        :body => fixture_data('categories-934787.json'),
        :content_type => 'application/json'
      )
      @data = WikipediaApi.page_categories(934787)
      @data.sort! {|a,b| a['pageid'] <=> b['pageid']}
    end

    it "should return 4 results" do
      @data.size.should == 4
    end

    it "should return a title for the first result" do
      @data.first['title'].should == 'Category:Villages in Fife'
    end

    it "should return the article display title" do
      @data.first['displaytitle'].should == 'Category:Villages in Fife'
    end

    it "should return a pageid for the first result" do
      @data.first['pageid'].should == 4309010
    end

    it "should return a namespace for the first result" do
      @data.first['ns'].should == 14
    end
  end
end
