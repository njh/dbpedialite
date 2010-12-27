require 'wikipedia_api'
require 'freebase_api'


class WikipediaThing
  BASE_URI = "http://dbpedialite.org/things"

  attr_accessor :pageid
  attr_accessor :title
  attr_accessor :abstract
  attr_accessor :longitude, :latitude
  attr_accessor :externallinks
  attr_accessor :updated_at

  # Additionally:
  #  foaf:depiction
  #  skos:subject
  #  dbpedia-owl:abstract
  #  dbpprop:reference (External Links)
  #  dbpprop:redirect
  #  dbpprop:disambiguates

  # Document properties
  #  lasttouched, lastrevid, ns, length, counter

  def self.for_title(title)
    data = WikipediaApi.title_to_pageid(title)
    if data.size and data.values.first
      self.new(data.values.first)
    else
      nil
    end
  end

  def self.load(pageid)
    @thing = self.new(pageid)
    @thing.load ? @thing : nil
  end

  def initialize(pageid, args={})
    @pageid = pageid
    @externallinks = []
    assign(args) unless args.empty?
  end

  # FIXME: is there a more generic way to do this?
  def assign(args)
    args.each_pair do |key,value|
      key = key.to_sym
      if self.respond_to?("#{key}=")
        self.send("#{key}=", value)
      end
    end
  end

  def uri
    @uri ||= RDF::URI.parse("#{BASE_URI}/#{pageid}#thing")
  end

  def doc_uri
    @doc_uri ||= RDF::URI.parse("#{BASE_URI}/#{pageid}")
  end

  def load
    data = WikipediaApi.parse(pageid)
    return false if data.nil? or !data['valid']

    assign(data)

    # Add the external links
    if data.has_key?('externallinks')
      self.externallinks = data['externallinks'].map {|link| RDF::URI.parse(link)}
    end

    # Add the images
    #if data.has_key?('images')
    #  self.images = data['images'].map {|img| RDF::URI.parse(img)}
    #end

    true
  end

  def wikipedia_uri
    @wikipedia_uri ||= RDF::URI.parse("http://en.wikipedia.org/wiki/#{escaped_title}")
  end

  def dbpedia_uri
    @dbpedia_uri ||= RDF::URI.parse("http://dbpedia.org/resource/#{escaped_title}")
  end

  def freebase_uri
    # Attempt to match to Freebase, but silently fail on error
    @freebase_uri ||= begin
      data = FreebaseApi.lookup_wikipedia_pageid(pageid)
      RDF::URI.parse(data['rdf_uri']) unless data.nil?
    rescue Timeout::Error => e
      $stderr.puts "Timed out while reading from Freebase: #{e.message}"
    rescue => e
      $stderr.puts "Error while reading from Freebase: #{e.message}"
    end
  end

  def escaped_title
    unless title.nil?
      CGI::escape(title.gsub(' ','_'))
    end
  end

  def has_coordinates?
    !(latitude.nil? || longitude.nil?)
  end

  def to_rdf
    RDF::Graph.new do |graph|
      # Triples about the Document
      graph << [doc_uri, RDF.type, RDF::FOAF.Document]
      graph << [doc_uri, RDF::DC.modified, updated_at] unless updated_at.nil?
      graph << [doc_uri, RDF::FOAF.primaryTopic, self.uri]

      # Triples about the Thing
      graph << [self.uri, RDF.type, RDF::OWL.Thing]
      graph << [self.uri, RDF::RDFS.label, title]
      graph << [self.uri, RDF::RDFS.comment, abstract]
      graph << [self.uri, RDF::FOAF.isPrimaryTopicOf, wikipedia_uri]
      graph << [self.uri, RDF::OWL.sameAs, dbpedia_uri]
      graph << [self.uri, RDF::OWL.sameAs, freebase_uri] unless freebase_uri.nil?
      graph << [self.uri, RDF::GEO.lat, latitude] unless latitude.nil?
      graph << [self.uri, RDF::GEO.long, longitude] unless longitude.nil?
      externallinks.each do |link|
        graph << [self.uri, RDF::FOAF.page, link]
      end
    end
  end

end
