$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))

require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'dbpedialite'
run DbpediaLite
