ROOT_DIR = File.expand_path(File.dirname(__FILE__))
$:.unshift(ROOT_DIR, File.join(ROOT_DIR, 'lib'))

require 'rubygems'
require 'bundler'

Bundler.require(:default)

require 'dbpedialite'
run DbpediaLite
