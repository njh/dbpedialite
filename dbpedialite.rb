#!/usr/bin/ruby

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))

require 'rubygems'
require 'sinatra'
require 'lib/wikipedia_article'
require 'erb'

get '/' do
  erb :index
end

get '/resource/:slug' do
  article = WikipediaArticle.find(:titles => params[:slug])
  redirect "/pageid/#{article.pageid}", 303
end

get '/pageid/:pageid' do
  erb "<pre>"+
    WikipediaArticle.find(:pageids => params[:pageid]).to_yaml+
  "</pre>"
end
