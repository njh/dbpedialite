require 'mediawiki_api'

class WikidataApi < MediaWikiApi

  def self.api_uri
    URI.parse('http://wikidata.org/w/api.php')
  end

  def self.get_sitelink(id, site='enwiki')
    data = self.get('wbgetitems', {
      :ids => id,
      :sites => site,
      :props => 'sitelinks',
      :languages => 'en'
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

  def self.find_by_title(title, site='enwiki')
    data = self.get('wbgetitems', {
      :titles => title,
      :sites => site,
      :props => 'info|aliases|labels|descriptions',
      :languages => 'en'
    })

    if data['items'].nil?
      raise MediaWiki::Exception.new('Empty response')
    elsif data['items'].empty?
      raise MediaWiki::NotFound.new('Failed to lookup title in Wikidata')
    end

    data['items'].values.first
  end

end
