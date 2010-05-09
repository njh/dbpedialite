#!/usr/bin/ruby

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))

require 'rubygems'
require 'sinatra'
require 'lib/wikipedia_article'
require 'erb'

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
  
  def link_to(title, url=nil)
    url = title if url.nil?
    "<a href=\"#{h url}\">#{h title}</a>"
  end
  
  def nl2p(text)
    paragraphs = text.to_s.split(/[\n\r]+/)
    paragraphs.map {|para| "<p>#{para}</p>"}.join
  end
end


get '/' do
  erb :index
end

get '/title/:title' do
  @article = WikipediaArticle.new(nil, :title => params[:title])
  redirect "/resource/#{@article.pageid}", 301
end

get '/resource/:pageid' do
  headers 'Vary' => 'Accept'
  accept = request.accept.first
  accept.sub!(/;.+$/,'') unless accept.nil?
  case accept
    when 'application/xml', 'application/xhtml+xml', 'text/html' then
      redirect "/page/#{params[:pageid]}", 303
    else
      redirect "/data/#{params[:pageid]}", 303
  end
end

get '/page/:pageid' do
  @article = WikipediaArticle.new(params[:pageid].to_i)
  @article.load
  erb :page
end

get '/data/:pageid' do
  # FIXME: add support for content negotiation
  headers 'Content-Type' => 'text/plain'
  @article = WikipediaArticle.new(params[:pageid].to_i)
  @article.load
  @article.dump(:ntriples)
end
