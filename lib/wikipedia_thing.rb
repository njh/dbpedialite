require 'wikipedia_api'
require 'freebase_api'
require 'base_model'


class WikipediaThing < BaseModel
  identifier_path "things"

  has :abstract, :kind => String, :default => nil
  has :longitude, :kind => Float, :default => nil
  has :latitude, :kind => Float, :default => nil
  has :externallinks, :kind => Array, :default => []
  has :updated_at, :kind => DateTime, :default => nil

  # Additionally:
  #  foaf:depiction
  #  skos:subject
  #  dbpedia-owl:abstract
  #  dbpprop:reference (External Links)
  #  dbpprop:redirect
  #  dbpprop:disambiguates

  # Document properties
  #  lasttouched, lastrevid, ns, length, counter

  def load
    data = WikipediaApi.parse(pageid)
    return false if data.nil? or !data['valid']

    update(data)

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

  def freebase_guid_uri
    fetch_freebase_uris
    @freebase_guid_uri
  end

  def freebase_mid_uri
    fetch_freebase_uris
    @freebase_mid_uri
  end

  def fetch_freebase_uris
    # Only make call to freebase once
    unless @called_freebase
      @called_freebase = true
      # Attempt to match to Freebase, but silently fail on error
      begin
        data = FreebaseApi.lookup_wikipedia_pageid(pageid)
        unless data.nil?
          @freebase_mid_uri = RDF::URI.parse("http://rdf.freebase.com/ns/"+data['mid'].sub('/m/','m.'))
          @freebase_guid_uri = RDF::URI.parse("http://rdf.freebase.com/ns/"+data['guid'].sub('#','guid.'))
        end
      rescue Timeout::Error => e
        $stderr.puts "Timed out while reading from Freebase: #{e.message}"
      rescue => e
        $stderr.puts "Error while reading from Freebase: #{e.message}"
      end
    end
  end

  def has_coordinates?
    !(latitude.nil? || longitude.nil?)
  end

  def label
    title
  end

  def to_rdf
    RDF::Graph.new do |graph|
      # Triples about the Document
      graph << [doc_uri, RDF.type, RDF::FOAF.Document]
      graph << [doc_uri, RDF::DC.title, "dbpedia lite thing - #{label}"]
      graph << [doc_uri, RDF::DC.modified, updated_at] unless updated_at.nil?
      graph << [doc_uri, RDF::FOAF.primaryTopic, self.uri]

      # Triples about the Thing
      graph << [self.uri, RDF.type, RDF::OWL.Thing]
      graph << [self.uri, RDF::RDFS.label, label]
      graph << [self.uri, RDF::RDFS.comment, abstract]
      graph << [self.uri, RDF::FOAF.isPrimaryTopicOf, wikipedia_uri]
      graph << [self.uri, RDF::OWL.sameAs, dbpedia_uri]
      graph << [self.uri, RDF::OWL.sameAs, freebase_guid_uri] unless freebase_guid_uri.nil?
      graph << [self.uri, RDF::OWL.sameAs, freebase_mid_uri] unless freebase_mid_uri.nil?
      graph << [self.uri, RDF::GEO.lat, latitude] unless latitude.nil?
      graph << [self.uri, RDF::GEO.long, longitude] unless longitude.nil?
      externallinks.each do |link|
        graph << [self.uri, RDF::FOAF.page, link]
      end
    end
  end

end
