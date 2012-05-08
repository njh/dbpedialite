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
  has :freebase_guid, :kind => String, :default => nil
  has :freebase_mid, :kind => String, :default => nil


  def load
    data = WikipediaApi.parse(pageid)

    update(data)

    # Add the external links
    if data.has_key?('externallinks')
      self.externallinks = data['externallinks'].map {|link| RDF::URI.parse(link)}
    end

    # Add the images
    #if data.has_key?('images')
    #  self.images = data['images'].map {|img| RDF::URI.parse(img)}
    #end
  end

  def freebase_guid
    fetch_freebase_uris
    @freebase_guid
  end

  def freebase_mid
    fetch_freebase_uris
    @freebase_mid
  end

  def freebase_guid_uri
    fetch_freebase_uris
    if freebase_guid
      @freebase_guid_uri ||= RDF::URI.parse("http://rdf.freebase.com/ns/"+freebase_guid.sub('#','guid.'))
    end
  end

  def freebase_mid_uri
    fetch_freebase_uris
    if freebase_mid
      @freebase_mid_uri ||= RDF::URI.parse("http://rdf.freebase.com/ns/"+freebase_mid.sub('/m/','m.'))
    end
  end

  def fetch_freebase_uris
    # Only make call to freebase once
    unless @called_freebase
      @called_freebase = true
      # Attempt to match to Freebase, but silently fail on error
      begin
        data = FreebaseApi.lookup_wikipedia_pageid(pageid)
        self.freebase_mid = data['mid']
        self.freebase_guid = data['guid']
      rescue Timeout::Error => e
        $stderr.puts "Timed out while reading from Freebase: #{e.message}"
      rescue FreebaseApi::Exception => e
        $stderr.puts "Error while reading from Freebase: #{e.message}"
      end
    end
  end

  def has_coordinates?
    !(latitude.nil? || longitude.nil?)
  end

  def label
    displaytitle || title
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
