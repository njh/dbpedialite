#!/usr/bin/env ruby
#
# This script fetches the Wikipedia english front page
# scans it for links to articles, looks each of them up,
# and submits the dbpedialite.org URI for them to Sindice
# and Ping The Semantic Web.
#

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'net/http'
require 'nokogiri'
require 'json'
require 'wikipedia_api'

USER_AGENT = 'Dbpedialite/1'
HTTP_TIMEOUT = 10

def get_links(url)
  url = URI.parse(url) unless url.is_a?(URI)

  res = Net::HTTP.start(url.host, url.port) do |http|
    http.get(url.request_uri)
  end
  
  # Check it was a 200
  if res.code != '200'
    raise "Failed to GET #{url} #{res.message}"
  end

  links = []
  doc = Nokogiri::HTML(res.body)
  doc.xpath("//body//a").each do |a|
    if a.has_attribute?('href') and a['href'].match(%r[/wiki/(.+)$])
      links << URI.unescape($1)
    end
  end
  links.sort.uniq
end

def ping_sindice(data)
  uri = URI.parse("http://api.sindice.com/v2/ping")
  begin
    req = Net::HTTP::Post.new(uri.request_uri)
    req['User-Agent'] = USER_AGENT
    req['Content-Type'] = 'text/plain'
    req['Content-Length'] = data.length
    req['Accept'] = 'text/plain'
    req.body = data
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = HTTP_TIMEOUT
      http.open_timeout = HTTP_TIMEOUT
      http.request(req)
    end
    raise res.body unless res.code == '200'
    puts "Sindice Response: #{res.body}"
  rescue Exception => e
    $stderr.puts "Failed to ping sindice: #{e}"
  end
end

def ping_the_semantic_web(ping_url)
  uri = URI.parse("http://pingthesemanticweb.com/rest/?url=#{URI.escape(ping_url)}")
  begin
    res = Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = HTTP_TIMEOUT
      http.open_timeout = HTTP_TIMEOUT
      http.get(uri.request_uri)
    end
    if res.code == '200' and res.body =~ /Thanks for pinging/
      puts "  => Ping OK"
    else
      raise res.body 
    end 
  rescue Exception => e
    $stderr.puts "Failed to ping the semantic web: #{e}"
  end
end



rdf_urls = []
links = get_links("http://en.wikipedia.org/wiki/Main_Page")
links.each do |link|
  puts "Looking up: #{link}"
  begin
    info = WikipediaApi.page_info(:titles => link)
    puts "  ns=#{info['ns']} pageid=#{info['pageid']}"
    #lastmod = Time.parse(info['touched'])
    if info['ns'] == 0
      rdf_url = "http://dbpedialite.org/things/#{info['pageid']}.rdf"
      ping_the_semantic_web(rdf_url)
      rdf_urls << rdf_url
    end
  rescue WikipediaApi::PageNotFound
  end
end

ping_sindice(
  rdf_urls.join("\n")
)
