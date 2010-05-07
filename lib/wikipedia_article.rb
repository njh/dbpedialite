require 'rubygems'
require 'net/http'
require 'json'
require 'cgi'
require 'uri'

class WikipediaArticle < OpenStruct
  USER_AGENT = 'DbpediaLite/1'
  WIKIPEDIA_API = URI.parse('http://en.wikipedia.org/w/api.php')

  def self.find(args)
  
    data = api_get({:action => 'query', :redirects => 1, :prop => 'info'}.merge(args))
    puts data
    
    # FIXME: check that a single page has been returned
    data['query']['pages'].values.first
  end
  
  def self.api_get(args)
    items = ['format=json']
    args.each_pair do |key,value|
     items.unshift CGI::escape(key.to_s)+'='+CGI::escape(value.to_s)
    end

    uri = WIKIPEDIA_API.clone
    uri.query = items.join('&')
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.get(uri.request_uri, {'User-Agent' => USER_AGENT})
    end
    
    # Throw exception if unsuccessful
    res.value
    
    JSON.parse(res.body)
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
