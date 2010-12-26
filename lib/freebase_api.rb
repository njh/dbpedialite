require 'uri'
require 'cgi'

module FreebaseApi
  USER_AGENT = 'DbpediaLite/1'
  MQLREAD_URI = URI.parse('http://www.freebase.com/api/service/mqlread')
  RDF_BASE_URI = URI.parse('http://rdf.freebase.com/rdf/')
  HTTP_TIMEOUT = 2

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
      raise "Freebase query failed: #{data['messages'][0]['message']}" 
    end
    
    data['result']
  end

  def self.lookup_wikipedia_pageid(pageid, language='en')
    data = mqlread({
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
    
    # Construct an rdf URI
    data['rdf_uri'] =  "http://rdf.freebase.com/ns/"+data['mid'].sub('/m/','m.')
    
    data
  end  
end
