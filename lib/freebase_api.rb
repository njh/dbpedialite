require 'uri'
require 'cgi'

module FreebaseApi
  USER_AGENT = 'DbpediaLite/1'
  MQLREAD_URI = URI.parse('http://www.freebase.com/api/service/mqlread')
  RDF_BASE_URI = URI.parse('http://rdf.freebase.com/rdf/')
  HTTP_TIMEOUT = 2

  class Exception < Exception
  end

  class NotFound < FreebaseApi::Exception
  end

  def self.mqlread(query)
    uri = MQLREAD_URI.clone
    uri.query = 'query='+CGI::escape(JSON.dump({'query' => query}))
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.open_timeout = HTTP_TIMEOUT
      http.read_timeout = HTTP_TIMEOUT
      http.get(uri.request_uri, {'User-Agent' => USER_AGENT})
    end

    # Throw an exception if HTTP request was unsuccessful
    res.value

    # Throw and exception if the JSON response was unsuccessful
    data = JSON.parse(res.body)
    unless data['code'] == '/api/status/ok'
      raise FreebaseApi::Exception.new("Freebase query failed: #{data['messages'][0]['message']}")
    end

    if data['result'].nil?
      raise FreebaseApi::NotFound.new("Freebase query failed return no results")
    end

    data['result']
  end

  def self.lookup_wikipedia_pageid(pageid, language='en')
    mqlread({
      'key' => {
        'namespace' => "/wikipedia/#{language}_id",
        'value' => pageid.to_s,
        'limit' => 0
       },
       'id' => nil,
       'name' => nil,
       'mid' => nil,
       'guid' => nil,
       'limit' => 1
    })
  end

  def self.lookup_by_id(identifier, language='en')
    mqlread({
      'id' => identifier,
      'key' => {
        'namespace' => "/wikipedia/#{language}_id",
        'value' => nil,
        'limit' => 1
      },
      'name' => nil,
      'mid' => nil,
      'guid' => nil,
      'limit' => 1
    })
  end

end
