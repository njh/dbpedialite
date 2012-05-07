require 'net/http'
require 'uri'

module WikipediaApi

  class Exception < Exception
  end

  class PageNotFound < WikipediaApi::Exception
  end

  class Redirect < WikipediaApi::Exception
    attr_reader :pageid
    attr_reader :title

    def initialize(pageid, title)
      @pageid = pageid
      @title = title
    end
  end

  USER_AGENT = 'DbpediaLite/1'
  API_URI = URI.parse('http://en.wikipedia.org/w/api.php')
  ABSTRACT_MAX_LENGTH = 500
  ABSTRACT_TRUNCATE_LENGTH = 800
  HTTP_TIMEOUT = 5

  def self.escape_query(str)
    URI::escape(str, ' ?#%"+=|')
  end

  def self.escape_title(title)
    URI::escape(title.gsub(' ','_'), ' ?#%"+=')
  end

  def self.clean_displaytitle(hash)
    if hash['displaytitle']
      hash['displaytitle'].gsub!(%r|<.+?>|, '')
    end
  end

  def self.page_info(args)
    data = self.get('query', {
      :prop => 'info',
      :inprop => 'displaytitle',
      :redirects => 1
    }.merge(args))

    if data['query'].nil? or data['query']['pages'].empty?
      raise WikipediaApi::Exception.new('Empty response')
    else
      info = data['query']['pages'].values.first
      if info.has_key?('missing')
        raise WikipediaApi::PageNotFound.new
      else
        clean_displaytitle(info)
        return info
      end
    end
  end

  def self.search(query, args={})
    data = self.get('query', {:list => 'search', :srprop => 'snippet|titlesnippet', :srsearch => query}.merge(args))

    data['query']['search']
  end

  def self.get(action, args={})
    items = []
    args.merge!(:action => action, :format => 'json')

    keys = args.keys.sort {|a,b| a.to_s <=> b.to_s}
    keys.each do |key|
     items << escape_query(key.to_s)+'='+escape_query(args[key].to_s)
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

    # Parse the response if it is JSON
    if res.content_type == 'application/json'
      data = JSON.parse(res.body)
    else
      raise WikipediaApi::Exception.new(
        "Response from Wikipedia API was not of type application/json."
      )
    end

    # Check for errors in the response
    if data.nil?
      raise WikipediaApi::Exception.new('Empty response')
    elsif data.has_key?('error')
      if data['error']['code'] == 'nosuchpageid'
        raise WikipediaApi::PageNotFound.new(
          data['error']['info']
        )
      else
        raise WikipediaApi::Exception.new(
          data['error']['info']
        )
      end
    end

    return data
  end

  def self.category_members(pageid, args={})
    data = self.get('query', {
      :generator => 'categorymembers',
      :gcmnamespace => '0|14',   # Only pages and sub-categories
      :gcmpageid => pageid,
      :gcmlimit => 500,
      :prop => 'info',
      :inprop => 'displaytitle'
    }.merge(args))

    data['query']['pages'].values
  end

  def self.page_categories(pageid, args={})
    data = self.get('query', {
      :generator => 'categories',
      :pageids => pageid,
      :prop => 'info',
      :inprop => 'displaytitle',
      :gcllimit => 500,
    }.merge(args))

    data['query']['pages'].values
  end


  def self.parse(pageid, args={})
    data = self.get('parse', {
      :prop => 'text|displaytitle',
      :pageid => pageid
    }.merge(args))

    data = data['parse']

    # Perform the screen-scraping
    text = Nokogiri::HTML(data['text']['*'])

    # Is it a redirect?
    redirect = text.at('/html/body/ol/li')
    if redirect and redirect.children.first.text == 'REDIRECT '
      redirect_title = redirect.at('a/@title')
      unless redirect_title.nil?
        info = self.page_info(:titles => redirect_title)
        # FIXME: hmm, maybe this isn't the best use of exceptions
        raise WikipediaApi::Redirect.new(info['pageid'], info['title'])
      end
    end

    # Get the last modified time for the comment at the end of the page
    comment = text.at('body').children.last
    if comment.inner_text.match(/Saved in parser cache with key (.+) and timestamp (\d+)/)
      data['updated_at'] = DateTime.strptime($2, "%Y%m%d%H%M%S")
    end

    # Extract the coordinates
    coordinates = text.at('#coordinates//span.geo')
    unless coordinates.nil?
      coordinates = coordinates.inner_text.split(/[^\d\-\.]+/)
      data['latitude'] = coordinates[0].to_f
      data['longitude'] = coordinates[1].to_f
    end

    # Extract images
    data['images'] = []
    text.search(".image/img").each do |img|
      next if img.attribute('width').value.to_i < 100
      next if img.attribute('height').value.to_i < 100
      image = img.attribute('src').value
      image.sub!(%r[/thumb/],'/')
      image.sub!(%r[/(\d+)px-(.+?)\.(\w+)$],'')

      # Fix for protocol-relative URLs
      # http://lists.wikimedia.org/pipermail/mediawiki-api-announce/2011-July/000023.html
      image = "http:#{image}" if image[0..1] == '//'

      data['images'] << image
    end
    data['images'].uniq!

    # Extract external links
    data['externallinks'] = []
    text.search("ul/li/a.external").each do |link|
      if link.has_attribute?('href')
        href = link.attribute('href').value
        next if href =~ %r[^(\w*):?//(\w+)\.wikipedia\.org/]
        data['externallinks'] << href
      end
    end
    data['externallinks'].uniq!

    # Extract the abstract from the body of the page
    data['abstract'] = extract_abstract(text)

    # Clean up the display title (remove HTML tags)
    clean_displaytitle(data)

    data
  end

  def self.extract_abstract(text)
    # Extract the abstract
    abstract = ''

    text.at('body').children.each do |node|

      # Look for paragraphs
      if node.name == 'p'
        # Remove references and other super-scripts
        node.css('sup').each { |sup| sup.remove }

        # Remove co-ordinates
        node.css('#coordinates').each { |coor| coor.remove }

        # Remove pronunciation and append the paragraph
        abstract += node.inner_text + "\n"
      end

      # Stop when we see the table of contents
      break if node.attribute('id') and node.attribute('id').value == 'toc'

      # Or we have enough text
      break if abstract.size > ABSTRACT_MAX_LENGTH
    end

    # Remove pronunciation and append the paragraph
    abstract = self.strip_pronunciation(abstract)

    # Remove trailing whitespace
    abstract.strip!

    # Truncate if the abstract is too long
    if (abstract.length > ABSTRACT_TRUNCATE_LENGTH)
      abstract.slice!(ABSTRACT_TRUNCATE_LENGTH-3)

      # Remove trailing partial word and replace with an ellipsis
      abstract.sub!(/[^\w\s]?\s*\w*$/, '...')
    end

    return abstract
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
