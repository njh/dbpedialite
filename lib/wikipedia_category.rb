require 'base_model'
require 'wikipedia_api'
require 'wikipedia_thing'

class WikipediaCategory < BaseModel
  identifier_path "categories"

  has :things, :collect => WikipediaThing
  has :subcategories, :collect => WikipediaCategory

  def load
    data = WikipediaApi.page_info(:pageids => pageid)

    # Is it actually a category?
    unless data['ns'] == 14
      raise WikipediaApi::PageNotFound.new("Page #{pageid} is not a category")
    end

    # Update object properties with the data that was loaded
    update(data)

    data = WikipediaApi.category_members(pageid)
    data.each do |member|
      case member['ns']
        when 0
          self.things << WikipediaThing.new(member)
        when 14
          self.subcategories << WikipediaCategory.new(member)
      end
    end

    true
  end

  def label
    @label ||= displaytitle.sub(/^Category:/,'')
  end

  def to_rdf
    RDF::Graph.new(doc_uri) do |graph|
      # Triples about the Document
      graph << [doc_uri, RDF.type, RDF::FOAF.Document]
      graph << [doc_uri, RDF::DC.title, "dbpedia lite category - #{label}"]
      graph << [doc_uri, RDF::FOAF.primaryTopic, self.uri]

      # Triples about the Concept
      graph << [self.uri, RDF.type, RDF::SKOS.Concept]
      graph << [self.uri, RDF::RDFS.label, label]
      graph << [self.uri, RDF::SKOS.prefLabel, label]
      graph << [self.uri, RDF::FOAF.isPrimaryTopicOf, wikipedia_uri]
      graph << [self.uri, RDF::OWL.sameAs, dbpedia_uri]
      things.each do |thing|
        graph << [thing.uri, RDF::SKOS.subject, self.uri]
        graph << [thing.uri, RDF::RDFS.label, thing.title]
      end
    end
  end
end
