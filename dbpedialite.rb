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


def extract_vocabularies(graph)
  vocabs = {}
  graph.predicates.each do |predicate|
    RDF::Vocabulary.each do |vocab|
      if predicate.to_s.index(vocab.to_uri.to_s) == 0
        vocab_name = vocab.__name__.split('::').last.downcase
        unless vocab_name.empty?
          vocabs[vocab_name.to_sym] = vocab
          break
        end
      end
    end
  end
  vocabs
end

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

  def shorten(uri)
    qname = uri.qname.join(':') rescue uri.to_s
    escape_html(qname)
  end

  def format_xmlns(vocabularies)
    if vocabularies
      xmlns = ''
      vocabularies.each_pair do |prefix,vocab|
        xmlns += " xmlns:#{h prefix}=\"#{h vocab.to_uri}\""
      end
      xmlns
    end
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
  @article = WikipediaArticle.for_title(title)
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

  headers 'Vary' => 'Accept',
          'Cache-Control' => 'public,max-age=600'
  case format
    when '', '*/*', 'html', 'application/xml', 'application/xhtml+xml', 'text/html' then
      @vocabularies = extract_vocabularies(@article)
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
