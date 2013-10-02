# encoding: utf-8
require 'spec_helper'
require 'mediawiki_api'

describe MediaWikiApi do

  context "escaping a page title" do
    it "should convert 'AC/DC' to 'AC/DC'" do
      MediaWikiApi.escape_title('AC/DC').should == 'AC/DC'
    end

    it "should convert 'Category:Villages in Fife' to 'Category:Villages_in_Fife'" do
      MediaWikiApi.escape_title('Category:Villages in Fife').should == 'Category:Villages_in_Fife'
    end

    it "should convert 'Who Censored Roger Rabbit?' to 'Who_Censored_Roger_Rabbit%3F'" do
      MediaWikiApi.escape_title('Who Censored Roger Rabbit?').should == 'Who_Censored_Roger_Rabbit%3F'
    end

    it "should convert '100% (song)' to '100%25_(song)'" do
      MediaWikiApi.escape_title('100% (song)').should == '100%25_(song)'
    end

    it "should convert 'C#' to 'C%23'" do
      MediaWikiApi.escape_title('C#').should == 'C%23'
    end

    it "should convert '2 + 2 = 5' to 'C%23'" do
      MediaWikiApi.escape_title('2 + 2 = 5').should == '2_%2B_2_%3D_5'
    end

    it "should convert 'Nat \"King\" Cole' to 'Nat_%22King%22_Cole'" do
      MediaWikiApi.escape_title('Nat "King" Cole').should == 'Nat_%22King%22_Cole'
    end

    it "should not convert '—We Also Walk Dogs' to '—We_Also_Walk_Dogs'" do
      MediaWikiApi.escape_title('—We Also Walk Dogs').force_encoding('utf-8').should == '—We_Also_Walk_Dogs'
    end
  end

  context "escaping a query parameter" do
    it "should convert 'Florence + the Machine' to 'Florence%20%2B%20the%20Machine'" do
      MediaWikiApi.escape_query('Florence + the Machine').should == 'Florence%20%2B%20the%20Machine'
    end

    it "should convert 'C#' to 'C%23'" do
      MediaWikiApi.escape_query('C#').should == 'C%23'
    end

    it "should convert 'Café' to 'Café'" do
      MediaWikiApi.escape_query('Café').should == 'Caf%C3%A9'
    end
  end
 
end
