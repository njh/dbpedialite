#!/usr/bin/env ruby
#
# Script to convert Wikipeda database export to owl:sameAs doucument.
#
# Information about the dump format here:
# http://meta.wikimedia.org/wiki/Data_dumps
#

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

STUB_ARTICLES_URL='http://dumps.wikimedia.org/enwiki/latest/enwiki-latest-stub-articles.xml.gz'
STUB_ARTICLES_FILE='enwiki-latest-stub-articles.xml'

require 'rubygems'
require 'nokogiri'
require 'rdf'
require 'uri'
require 'wikipedia_api'
include Nokogiri

class WikipediaStubsCallbacks < XML::SAX::Document
  attr_accessor :path
  attr_accessor :page_id
  attr_accessor :page_title

  def initialize(output)
    @writer = RDF::Writer.for(:ntriples).new(output)
  end
  
  def start_document
    self.path = []
  end

  def start_element(element, attrs)
    self.path.push(element)
    if self.path == ['mediawiki', 'page']
      self.page_id = nil
      self.page_title = ''
    end
  end
  
  def end_element(element)
    if self.path == ['mediawiki', 'page']
      @writer << [
        dbpedia_uri(page_title),
        RDF::OWL.sameAs,
        dbpedialite_uri(page_id)
      ]
    end
    self.path.pop
  end
  
  def characters(string)
    if self.path == ['mediawiki', 'page', 'id']
      self.page_id = string
    elsif self.path == ['mediawiki', 'page', 'title']
      self.page_title += string
    end
  end
  
  def dbpedia_uri(title)
    escaped = WikipediaApi.escape_title(title)
    RDF::URI("http://dbpedia.org/resource/#{escaped}")
  end
  
  def dbpedialite_uri(id)
    RDF::URI("http://dbpedialite.org/things/#{id}#id")
  end
end


# Download the latest version
unless File.exists? STUB_ARTICLES_FILE
  # FIXME: update automatically if file on sever is newer
  puts "Downloading #{STUB_ARTICLES_URL}..."
  system('curl', '-o', STUB_ARTICLES_FILE+'.gz', STUB_ARTICLES_URL) or
    raise "Failed to fetch article stubs file"

  # Decompress it
  puts "Unzipping #{STUB_ARTICLES_FILE}..."
  system('gunzip', STUB_ARTICLES_FILE+'.gz') or
    raise "Failed to de-compress article stubs file"
end

output = File.new("dbpedialite-sameas.nt", "w")
parser = XML::SAX::Parser.new(WikipediaStubsCallbacks.new(output))
parser.parse_file(STUB_ARTICLES_FILE)
output.close
