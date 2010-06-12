#!/usr/bin/ruby

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))

require 'rubygems'
require 'sinatra'
require 'sinatra/content_for'
require 'lib/wikipedia_article'
require 'rdiscount'
require 'erb'

# Serialisers
require 'rdf/json'
require 'rdf/rdfxml'
require 'rdf/ntriples'


helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def link_to(title, url=nil, attr={})
    url = title if url.nil?
    attr.merge!('href' => url.to_s)
    attr_str = attr.keys.map {|k| "#{h k}=\"#{h attr[k]}\""}.join(' ')
    "<a #{attr_str}>#{h title}</a>"
  end

  def nl2p(text)
    paragraphs = text.to_s.split(/[\n\r]+/)
    paragraphs.map {|para| "<p>#{para}</p>"}.join
  end
  
  # FIXME: do this properly
  def shorten(uri)
    str = uri.to_s
    str.gsub!('http://xmlns.com/foaf/0.1/','foaf:')
    str.gsub!('http://purl.org/dc/terms/','dcterms:')
    str.gsub!('http://www.w3.org/2003/01/geo/wgs84_pos#','geo:')
    str.gsub!('http://www.w3.org/2000/01/rdf-schema#','rdfs:')
    str.gsub!('http://www.w3.org/2002/07/owl#','owl:')
    str.gsub!('http://www.w3.org/1999/02/22-rdf-syntax-ns#','rdf:')
    escape_html(str)
  end
  
end

## FIXME: this shouldn't be needed
before do
  Spira.add_repository! :default, RDF::Repository.new
end
  
get '/' do
  headers 'Cache-Control' => 'public,max-age=3600'
  @readme = RDiscount.new(File.read(File.join(File.dirname(__FILE__), 'README.md')))
  erb :index
end

get '/search' do
  headers 'Cache-Control' => 'public,max-age=600'
  redirect '/' if params[:q].nil? or params[:q].empty?

  @results = WikipediaApi.search(params[:q], :srlimit => 20)
  @results.each do |result|
    escaped = CGI::escape(result['title'].gsub(' ','_'))
    result['url'] = "/titles/#{escaped}"
  end

  erb :search
end

get '/titles/:title' do |title|
  @article = WikipediaArticle.find_title(title)
  not_found("Title not found.") if @article.nil?

  headers 'Cache-Control' => 'public,max-age=600'
  redirect "/things/#{@article.pageid}", 301
end

get %r{^/things/(\d+)\.?(\w*)$} do |pageid,format|
  @article = WikipediaArticle.load(pageid)
  not_found("Thing not found.") if @article.nil?

  if format.empty?
    format = request.accept.first || ''
    format.sub!(/;.+$/,'')
  end

  # FIXME: do this better
  # @namespaces = [:dc, :foaf, :geo, :owl, :rdfs]
  @namespaces =
    ' xmlns:dcterms="http://purl.org/dc/terms/"'+
    ' xmlns:foaf="http://xmlns.com/foaf/0.1/"'+
    ' xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"'+
    ' xmlns:owl="http://www.w3.org/2002/07/owl#"'+
    ' xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"'


  headers 'Vary' => 'Accept',
          'Cache-Control' => 'public,max-age=600'
  case format
    when '', '*/*', 'html', 'application/xml', 'application/xhtml+xml', 'text/html' then
      content_type 'text/html'
      erb :page
    when 'nt', 'ntriples', 'text/plain' then
      content_type 'text/plain'
      @article.dump(:ntriples)
    when 'json', 'application/json', 'text/json' then
      content_type 'application/json'
      @article.dump(:json)
    when 'rdf', 'xml', 'rdfxml', 'application/rdf+xml', 'text/rdf' then
      content_type 'application/rdf+xml'
      @article.dump(:rdfxml)
    else
      error 400, "Unsupported format: #{format}\n"
  end
end
