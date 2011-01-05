#!/usr/bin/env ruby
#
# Script to convert Wikipeda database export to owl:sameAs doucument.
#
# Download 'stub-articles.xml.gz' available from:
#   http://download.wikimedia.org/enwiki/
#
# Tested using enwiki-20100130-stub-articles.xml
#

require 'rubygems'
require 'nokogiri'
require 'rdf'
require 'uri'
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
      self.page_title = nil
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
      self.page_title = string
    end
  end
  
  def dbpedia_uri(title)
    # FIXME: which characters does dbpedia.org escape?
    escaped = URI.escape(title.gsub(' ','_'), '/;=?,+')
    RDF::URI("http://dbpedia.org/resource/#{escaped}")
  end
  
  def dbpedialite_uri(id)
    RDF::URI("http://dbpedialite.org/things/#{id}#id")
  end
end


output = File.new("dbpedialite-sameas.nt", "w")
parser = XML::SAX::Parser.new(WikipediaStubsCallbacks.new(output))
parser.parse_file("enwiki-20100130-stub-articles.xml")
output.close
