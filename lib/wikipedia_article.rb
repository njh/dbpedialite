require 'rubygems'
require 'net/http'
require 'json'
require 'cgi'
require 'uri'

class WikipediaArticle < OpenStruct
  USER_AGENT = 'DbpediaLite/1'

  def self.find(args)
    uri_str = "http://en.wikipedia.org/w/api.php?action=query&redirects&prop=info&format=json"
    args.each_pair do |key,value|
      uri_str += '&'+CGI::escape(key.to_s)+'='+CGI::escape(value.to_s)
    end
    
    uri = URI.parse(uri_str)
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.request_uri, {'User-Agent' => USER_AGENT})
    end
    
    # Throw exception if unsuccessful
    res.value
    
    # FIXME: check that a single page has been returned
    
    self.new(JSON.parse(res.body)['query']['pages'].values.first)
  end
  
  def initialize(args=nil)
    super
  
    case args
      when Hash
        args.each_pair do |key,value|
          self.send("#{key}=", value)
        end
      when String
        self.title = args
      when Integer
        self.pageid = args
      else
        raise "Don't know to create a WikipediaArticle from a #{args.class}"
    end
  end

end
