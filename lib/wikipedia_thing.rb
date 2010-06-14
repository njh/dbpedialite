require 'rubygems'
require 'wikipedia_api'
require 'freebase_api'
require 'spira'
require 'rdf/geo'


class WikipediaThing
  include Spira::Resource

  base_uri "http://dbpedialite.org/things"
  type OWL.Thing

  property :title, :predicate => RDFS.label, :type => String
  property :abstract, :predicate => RDFS.comment, :type => String
  property :page, :predicate => FOAF.page, :type => URI
  property :latitude, :predicate => GEO.lat, :type => Float
  property :longitude, :predicate => GEO.long, :type => Float
  property :dbpedia, :predicate => OWL.sameAs, :type => URI
  property :freebase, :predicate => OWL.sameAs, :type => URI

  #has_many :categories, :predicate => SKOS.subject, :type => :Category

  # FIXME: this should apply to the document, not the thing
  #property :updated_at, :predicate => DC.modified, :type => DateTime

  # Additionally:
  #  foaf:depiction
  #  skos:subject
  #  foaf:page
  #  dbpedia-owl:abstract
  #  dbpprop:reference (External Links)
  #  dbpprop:redirect
  #  dbpprop:disambiguates

  # Document properties
  #  lasttouched, lastrevid, ns, length, counter

  def self.id_for(identifier)
    unless identifier.is_a?(RDF::URI)
      identifier = RDF::URI.parse("#{base_uri}/#{identifier}#thing")
    end
    super(identifier)
  end

  def self.for_title(title)
    data = WikipediaApi.title_to_pageid(title)
    if data.size and data.values.first
      self.for(data.values.first)
    else
      nil
    end
  end

  def self.load(identifier, opts={})
    @thing = self.for(identifier, opts)
    @thing.load ? @thing : nil
  end

  def load
    data = WikipediaApi.parse(pageid)
    return false unless data['valid']
    self.class.properties.each do |name,property|
      name = name.to_s
      if data.has_key?(name)
        self.send("#{name}=", data[name])
      end
    end

    # Attempt to match to Freebase, but silently fail on error
    begin
      data = FreebaseApi.lookup_wikipedia_pageid(pageid)
      self.freebase = RDF::URI.parse(data['rdf_uri'])
    rescue Timeout::Error => e
      $stderr.puts "Timed out while reading from Freebase: #{e.message}"
    rescue => e
      $stderr.puts "Error while reading from Freebase: #{e.message}"
    end

    true
  end

  def title=(title)
    attribute_set(:title, title)

    # The FOAF::page is derived from the title
    unless title.nil?
      self.page = RDF::URI.parse("http://en.wikipedia.org/wiki/#{escaped_title}")
      self.dbpedia = RDF::URI.parse("http://dbpedia.org/resource/#{escaped_title}")
    end
  end

  def pageid
    self.uri.path =~ /(\d+)$/
    $1.to_i
  end

  def escaped_title
    unless title.nil?
      CGI::escape(title.gsub(' ','_'))
    end
  end

  def has_coordinates?
    !(latitude.nil? || longitude.nil?)
  end

  def dump(args)
    RDF::Writer.for(*args).dump(self)
  end
end
