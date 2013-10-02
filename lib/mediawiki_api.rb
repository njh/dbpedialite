require 'net/http'
require 'uri'

class MediaWikiApi

  USER_AGENT = 'DbpediaLite/1'
  HTTP_TIMEOUT = 5
  NBSP = Nokogiri::HTML("&nbsp;").text
  UNSAFE_REGEXP = Regexp.new('[^-_\.!~*\'()a-zA-Z0-9;/:@&=$,]', false, 'N').freeze

  class Exception < Exception
  end

  class NotFound < MediaWikiApi::Exception
  end

  def self.escape_query(str)
    URI::escape(str, UNSAFE_REGEXP)
  end

  def self.escape_title(title)
    URI::escape(title.gsub(' ','_'), ' ?#%"+=').force_encoding('UTF-8')
  end

  def self.get(action, args={})
    items = []
    args.merge!(:action => action, :format => 'json')

    keys = args.keys.sort {|a,b| a.to_s <=> b.to_s}
    keys.each do |key|
     items << escape_query(key.to_s)+'='+escape_query(args[key].to_s)
    end

    uri = self.api_uri
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
      raise MediaWikiApi::Exception.new(
        "Response from MediaWiki API was not of type application/json."
      )
    end

    # Check for errors in the response
    if data.nil?
      raise MediaWikiApi::Exception.new('Empty response')
    elsif data.has_key?('error')
      if data['error']['code'] == 'nosuchpageid'
        raise MediaWikiApi::NotFound.new(
          data['error']['info']
        )
      else
        raise MediaWikiApi::Exception.new(
          data['error']['info']
        )
      end
    end

    return data
  end

end
