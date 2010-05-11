require 'rubygems'
require 'wikipedia_api'
require 'spira'

GEO = RDF::Vocabulary.new('http://www.w3.org/2003/01/geo/wgs84_pos#')


class WikipediaArticle
  include Spira::Resource

  base_uri "http://dbpedialite.org/things"
  type RDF::OWL.Thing

  property :title, :predicate => RDF::RDFS.label, :type => String
  property :abstract, :predicate => RDF::RDFS.comment, :type => String
  property :page, :predicate => RDF::FOAF.page, :type => RDF::URI
  property :latitude, :predicate => GEO.lat, :type => Float
  property :longitude, :predicate => GEO.long, :type => Float
  property :dbpedia, :predicate => RDF::OWL.sameAs, :type => RDF::URI

  # FIXME: this should apply to the document, not the thing
  #property :updated_at, :predicate => RDF::DC.modified, :type => DateTime

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

  def initialize(identifier, opts = {})
    if identifier.nil? and opts[:title]
      data = WikipediaApi.query(:titles => opts[:title])
      identifier = data['pageid']
    end

    unless identifier.is_a?(RDF::URI)
      identifier = RDF::URI.parse("#{self.class.base_uri}/#{identifier}#thing")
    end

    super(identifier, opts)
  end

  def load
    data = WikipediaApi.parse(pageid)
    self.class.properties.each do |name,property|
      if data.has_key?(name)
        self.send("#{name}=", data[name])
      end
    end
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
end
