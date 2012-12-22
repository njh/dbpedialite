require 'mediawiki_api'

class WikidataApi < MediaWikiApi

  def self.api_uri
    URI.parse('http://wikidata.org/w/api.php')
  end

  def self.get_sitelink(id, site='enwiki')
    data = self.get('wbgetentities', {
      :ids => id,
      :sites => site,
      :props => 'sitelinks',
      :languages => 'en'
    })

    if data['entities'].nil?
      raise MediaWiki::Exception.new('Empty response')
    elsif data['entities'][id].nil?
      raise MediaWiki::NotFound.new('Wikidata identifier does not exist')
    elsif data['entities'][id]['sitelinks'][site].nil?
      raise MediaWiki::NotFound.new('Sitelink does not exist for Wikidata identifier')
    else
      return data['entities'][id]['sitelinks'][site]
    end
  end

  def self.find_by_title(title, site='enwiki')
    data = self.get('wbgetentities', {
      :titles => title,
      :sites => site,
      :props => 'info|aliases|labels|descriptions',
      :languages => 'en'
    })

    if data['entities'].nil?
      raise MediaWikiApi::Exception.new('Empty response')
    elsif data['entities'].empty? or data['entities'].keys.first == "-1"
      raise MediaWikiApi::NotFound.new('Failed to lookup title in Wikidata')
    end

    data['entities'].values.first
  end

end
