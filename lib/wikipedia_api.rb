require 'net/http'
require 'uri'
require 'cgi'

module WikipediaApi
  USER_AGENT = 'DbpediaLite/1'
  API_URI = URI.parse('http://en.wikipedia.org/w/api.php')
  ABSTRACT_MAX_LENGTH = 500
  ABSTRACT_TRUNCATE_LENGTH = 800
  HTTP_TIMEOUT = 5

  def self.page_info(args)
    data = self.get('query', {:redirects => 1, :prop => 'info'}.merge(args))

    unless data['query'].nil? or data['query']['pages'].empty?
      info = data['query']['pages'].values.first
      return info unless info.has_key?('missing')
    end
  end

  def self.search(query, args={})
    data = self.get('query', {:list => 'search', :prop => 'info', :srsearch => query}.merge(args))

    data['query']['search']
  end

  def self.get(action, args={})
    items = []
    args.merge!(:action => action, :format => 'json')

    keys = args.keys.sort {|a,b| a.to_s <=> b.to_s}
    keys.each do |key|
     items << CGI::escape(key.to_s)+'='+CGI::escape(args[key].to_s)
    end

    uri = API_URI.clone
    uri.query = items.join('&')
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = HTTP_TIMEOUT
      http.open_timeout = HTTP_TIMEOUT
      http.get(uri.request_uri, {'User-Agent' => USER_AGENT})
    end

    # Throw exception if unsuccessful
    res.value

    JSON.parse(res.body)

    # FIXME: throw an exception if Wikipedia reports a problem
  end

  def self.category_members(title, args={})
    # FIXME: this should use pageid, when it is available in the MediaWiki API
    data = self.get('query', {
      :list => 'categorymembers',
      :cmprop => 'ids|title',
      :cmsort => 'sortkey',
      :cmtitle => title,
      :cmlimit => 500
    }.merge(args))

    data['query']['categorymembers']
  end

  def self.page_categories(pageid, args={})
    data = self.get('query', {
      :generator => 'categories',
      :pageids => pageid,
      :gcllimit => 500,
    }.merge(args))

    data['query']['pages'].values
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

    # Extract images
    data['images'] = []
    doc.search(".image/img").each do |img|
      next if img.attribute('width').value.to_i < 100
      next if img.attribute('height').value.to_i < 100
      image = img.attribute('src').value
      image.sub!(%r[/thumb/],'/')
      image.sub!(%r[/(\d+)px-(.+?)\.(\w+)$],'')
      data['images'] << image
    end

    # Extract external links
    data['externallinks'] = []
    doc.search("ul/li/a.external").each do |link|
      if link.has_attribute?('href')
        href = link.attribute('href').value
        next if href =~ %r[^http://(\w+)\.wikipedia\.org/]
        data['externallinks'] << href
      end
    end
    data['externallinks'].uniq!

    # Extract the abstract
    data['abstract'] = ''
    doc.at('#bodyContent').children.each do |node|

      # Look for paragraphs
      if node.name == 'p'
        # Remove references and other super-scripts
        node.css('sup').each { |sup| sup.remove }

        # Remove co-ordinates
        node.css('#coordinates').each { |coor| coor.remove }

        # Remove pronunciation and append the paragraph
        data['abstract'] += node.inner_text + "\n"
      end

      # Stop when we see the table of contents
      break if node.attribute('id') and node.attribute('id').value == 'toc'

      # Or we have enough text
      break if data['abstract'].size > ABSTRACT_MAX_LENGTH
    end

    # Remove pronunciation and append the paragraph
    data['abstract'] = self.strip_pronunciation(data['abstract'])

    # Remove trailing whitespace
    data['abstract'].strip!

    # Truncate if the abstract is too long
    if (data['abstract'].length > ABSTRACT_TRUNCATE_LENGTH)
      data['abstract'].slice!(ABSTRACT_TRUNCATE_LENGTH-3)

      # Remove trailing partial word and replace with an ellipsis
      data['abstract'].sub!(/[^\w\s]?\s*\w*$/, '...')
    end

    # Is this a Not Found page?
    if data['abstract'] =~ /^The requested page title is invalid/
      data['valid'] = false
      return data
    else
      data['valid'] = true
    end

    data
  end

  def self.strip_pronunciation(string)
    result = string.dup
    regexes = [
      %r/\(.*?pronunciation:.*?\) /,
      %r[\(IPA: ["\[/].*?["\]/]\) ],
      %r[\(pronounced ["\[/].*?["\]/]\) ],
      # for when pronounciation is mixed in with birthdate, e.g. (pronounced /bəˈɹɛlɪs/; born December 7, 1979)
      %r[pronounced ["\[/].*?["\]/]\; ],
    ]
    regexes.each do |regex|
      if result =~ regex
        result.sub!(regex, '')
        break
      end
    end
    return result
  end
end
