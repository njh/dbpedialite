#!/usr/bin/ruby

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))

require 'rubygems'
require 'sinatra'
require 'lib/wikipedia_article'
require 'rdf/json'
require 'erb'

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
end


get '/' do
  headers 'Cache-Control' => 'public,max-age=3600'
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
  @article = WikipediaArticle.new(nil, :title => title)

  # FIXME: 404 if not found

  headers 'Cache-Control' => 'public,max-age=600'
  redirect "/things/#{@article.pageid}", 301
end

get %r{^/things/(\d+)\.?(\w*)$} do |pageid,format|
  @article = WikipediaArticle.new(pageid)
  @article.load

  # FIXME: 404 if not found

  if format.empty?
    format = request.accept.first || ''
    format.sub!(/;.+$/,'')
  end

  headers 'Vary' => 'Accept',
          'Cache-Control' => 'public,max-age=600'
  case format
    when 'html', 'application/xml', 'application/xhtml+xml', 'text/html' then
      content_type 'text/html'
      erb :page
    when '', '*/*', 'nt', 'ntriples', 'text/plain' then
      content_type 'text/plain'
      @article.dump(:ntriples)
    when 'json', 'application/json', 'text/json' then
      content_type 'application/json'
      @article.dump(:json)
    else
      error 400, "Unsupported format: #{format}\n"
  end
end
