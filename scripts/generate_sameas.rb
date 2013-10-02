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

  attr_accessor :namespaces
  attr_accessor :namespace_id

  def initialize(filename)
    @ntriples_file = File.new(filename+'.nt', "w")
    @tsv_file = File.new(filename+'.tsv', "w")
    @ntriples = RDF::Writer.for(:ntriples).new(@ntriples_file)
  end

  def start_document
    self.path = []
    self.namespaces = {}
  end

  def start_element(element, attrs)
    self.path.push(element)
    if self.path == ['mediawiki', 'page']
      self.page_id = nil
      self.page_title = ''
    elsif self.path == ['mediawiki', 'siteinfo', 'namespaces', 'namespace']
      attrs.each do |k,v|
        self.namespace_id = v if k == 'key'
      end
    end
  end

  def end_element(element)
    if self.path == ['mediawiki', 'page']
      # Check that this isn't a 'special page'
      if page_title.match(/^([a-zA-Z ]+):/) and namespaces.has_key?($1)
        if $1 == 'Category'
          type = 'categories'
        end
      else
        type = 'things'
      end

      unless type.nil?
        @tsv_file << dbpedialite_uri(page_id, type) + "\t"
        @tsv_file << dbpedia_uri(page_title) + "\n"

        @ntriples << [
          dbpedialite_uri(page_id, type),
          RDF::OWL.sameAs,
          dbpedia_uri(page_title)
        ]
      end
    elsif self.path == ['mediawiki', 'siteinfo', 'namespaces']
      puts "Namespaces: #{namespaces.inspect}"
    end
    self.path.pop
  end

  def characters(string)
    if self.path == ['mediawiki', 'page', 'id']
      self.page_id = string
    elsif self.path == ['mediawiki', 'page', 'title']
      self.page_title += string
    elsif self.path == ['mediawiki', 'siteinfo', 'namespaces', 'namespace']
      self.namespaces[string] = namespace_id
    end
  end

  def dbpedia_uri(title)
    escaped = WikipediaApi.title_to_dbpedia_key(title)
    RDF::URI("http://dbpedia.org/resource/#{escaped}")
  end

  def dbpedialite_uri(id, type='things')
    RDF::URI("http://www.dbpedialite.org/#{type}/#{id}#id")
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

callbacks = WikipediaStubsCallbacks.new('dbpedialite-sameas')
parser = XML::SAX::Parser.new(callbacks)
File.open(STUB_ARTICLES_FILE) do |file|
  parser.parse_io(file, 'UTF-8')
end
