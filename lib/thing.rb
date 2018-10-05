require 'wikipedia_api'
require 'wikidata_api'
require 'base_model'


class Thing < BaseModel
  identifier_path "things"

  has :abstract, :kind => String, :default => nil
  has :longitude, :kind => Float, :default => nil
  has :latitude, :kind => Float, :default => nil
  has :externallinks, :kind => Array, :default => []
  has :updated_at, :kind => DateTime, :default => nil
  has :wikidata_id, :kind => String, :default => nil
  has :wikidata_label, :kind => String, :default => nil
  has :wikidata_description, :kind => String, :default => nil

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

  def wikidata_id
    fetch_wikidata
    @wikidata_id
  end

  def wikidata_uri
    if wikidata_id
      @wikidata_uri ||= RDF::URI.parse("http://www.wikidata.org/entity/"+wikidata_id)
    end
  end

  def fetch_wikidata
    # Only make call to Wikidata once
    unless @called_wikidata
      @called_wikidata = true
      # Attempt to lookup in WikiData, but silently fail on error
      begin
        data = WikidataApi.find_by_title(title)
        if data.has_key?('id')
          self.wikidata_id = data['title']
          if data.has_key?('labels') and data['labels'].has_key?('en')
            self.wikidata_label = data['labels']['en']['value']
          end
          if data.has_key?('descriptions') and data['descriptions'].has_key?('en')
            self.wikidata_description = data['descriptions']['en']['value']
          end
        end
      rescue Timeout::Error => e
        $stderr.puts "Timed out while reading from Wikidata: #{e.message}"
      rescue MediaWikiApi::Exception => e
        $stderr.puts "Error while reading from Wikidata: #{e.message}"
      end
    end
  end

  def has_coordinates?
    !(latitude.nil? || longitude.nil?)
  end

  def label
    displaytitle || title
  end

  WIKIBASE = RDF::Vocabulary.new('http://www.wikidata.org/ontology#')
  SCHEMA = RDF::Vocabulary.new('http://schema.org/')
  CC = RDF::Vocabulary.new('http://creativecommons.org/ns#')

  CC_BY_SA_30 = RDF::URI("http://creativecommons.org/licenses/by-sa/3.0/")
  GNU_FDL_13 = RDF::URI("http://gnu.org/licenses/fdl-1.3.html")

  def to_rdf
    RDF::Graph.new do |graph|
      # Triples about the Document
      graph << [doc_uri, RDF.type, RDF::FOAF.Document]
      graph << [doc_uri, RDF::DC.title, "dbpedia lite thing - #{label}"]
      graph << [doc_uri, RDF::DC.modified, updated_at] unless updated_at.nil?
      graph << [doc_uri, RDF::FOAF.primaryTopic, self.uri]
      graph << [doc_uri, CC.license, CC_BY_SA_30]
      graph << [doc_uri, CC.license, GNU_FDL_13]

      # Triples about the Thing
      graph << [self.uri, RDF.type, RDF::OWL.Thing]
      graph << [self.uri, RDF::RDFS.label, label]
      graph << [self.uri, RDF::RDFS.comment, abstract]
      graph << [self.uri, RDF::FOAF.isPrimaryTopicOf, wikipedia_uri]
      graph << [self.uri, RDF::OWL.sameAs, dbpedia_uri]
      graph << [self.uri, RDF::GEO.lat, latitude] unless latitude.nil?
      graph << [self.uri, RDF::GEO.long, longitude] unless longitude.nil?

      # Triples about the Wikipedia page
      graph << [wikipedia_uri, RDF.type, SCHEMA.Article]
      graph << [wikipedia_uri, SCHEMA.about, self.uri]
      graph << [wikipedia_uri, SCHEMA.inLanguage, 'en']

      # Link to WikiData
      unless wikidata_id.nil?
        literal_label = RDF::Literal.new(wikidata_label, :language => :en) unless wikidata_label.nil?
        literal_description = RDF::Literal.new(wikidata_description, :language => :en) unless wikidata_description.nil?
        graph << [self.uri, RDF::OWL.sameAs, wikidata_uri]
        graph << [wikidata_uri, RDF.type, WIKIBASE.Item]
        graph << [wikidata_uri, RDF::RDFS.label, literal_label] unless literal_label.nil?
        graph << [wikidata_uri, SCHEMA.name, literal_label] unless literal_label.nil?
        graph << [wikidata_uri, SCHEMA.description, literal_description] unless literal_description.nil?
        graph << [wikipedia_uri, SCHEMA.about, wikidata_uri]
      end

      # External links
      externallinks.each do |link|
        graph << [self.uri, RDF::FOAF.page, link]
      end
    end
  end

end
