require 'mediawiki_api'

class WikidataApi < MediaWikiApi

  def self.api_uri
    URI.parse('http://wikidata.org/w/api.php')
  end

  def self.get_sitelink(id, site='enwiki')
    data = self.get('wbgetitems', {
      :ids => id,
      :props => 'sitelinks',
      :languages => 'en',
      :sites => site
    })

    if data['items'].nil?
      raise MediaWiki::Exception.new('Empty response')
    elsif data['items'][id].nil?
      raise MediaWiki::NotFound.new('Wikidata identifier does not exist')
    elsif data['items'][id]['sitelinks'][site].nil?
      raise MediaWiki::NotFound.new('Sitelink does not exist for Wikidata identifier')
    else
      return data['items'][id]['sitelinks'][site]
    end
  end
  
end
