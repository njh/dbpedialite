require 'rubygems'
require 'net/http'
require 'json'
require 'nokogiri'
require 'uri'
require 'cgi'


module WikipediaApi
  USER_AGENT = 'DbpediaLite/1'
  API_URI = URI.parse('http://en.wikipedia.org/w/api.php')
  ABSTRACT_MAX_LENGTH = 500

  def self.query(args)
    data = self.get('query', {:redirects => 1, :prop => 'info'}.merge(args))

    # FIXME: check that a single page has been returned
    data['query']['pages'].values.first
  end

  def self.search(query, args={})
    data = self.get('query', {:list => 'search', :prop => 'info', :srsearch => query}.merge(args))

    data['query']['search']
  end

  def self.get(action, args={})
    items = []
    args.merge!(:action => action, :format => 'json')
    args.each_pair do |key,value|
     items << CGI::escape(key.to_s)+'='+CGI::escape(value.to_s)
    end

    uri = API_URI.clone
    uri.query = items.join('&')
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.request_uri, {'User-Agent' => USER_AGENT})
    end

    # Throw exception if unsuccessful
    res.value

    JSON.parse(res.body)
  end

  def self.parse(pageid)
    # FIXME: this should use the API instead of screen scaping
    uri = URI.parse("http://en.wikipedia.org/wiki/index.php?curid=#{pageid}")
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.request_uri, {'User-Agent' => USER_AGENT})
    end

    # Throw exception if unsuccessful
    res.value

    # Perform the screen-scraping
    data = {}
    doc = Nokogiri::HTML(res.body)

    # Extract the abstract
    data['abstract'] = ''
    doc.search("#content//p").each do |para|
      # FIXME: filter out non-abstract spans properly
      next if para.inner_text =~ /^Coordinates:/
      # FIXME: stop at the contents table
      data['abstract'] += para.inner_text + "\n";
      break if data['abstract'].size > ABSTRACT_MAX_LENGTH
    end
    data['abstract'].gsub!(/\[\d+\]/,'')
    
    # Is this a Not Found page?
    if data['abstract'] =~ /^The requested page title is invalid/
      data['valid'] = false
      return data
    else
      data['valid'] = true
    end

    # Extract the title of the page
    title = doc.at('#firstHeading')
    data['title'] = title.inner_text unless title.nil?

    # Extract the last modified date
    lastmod = doc.at('#footer-info-lastmod')
    unless lastmod.nil?
      data['updated_at'] = DateTime.parse(
        lastmod.inner_text.sub('This page was last modified on ','')
      )
    end
    
    # Extract the coordinates
    coordinates = doc.at('#coordinates//span.geo')
    unless coordinates.nil?
      coordinates = coordinates.inner_text.split(/[^\d\-\.]+/)
      data['latitude'] = coordinates[0].to_f
      data['longitude'] = coordinates[1].to_f
    end


    data
  end

end
