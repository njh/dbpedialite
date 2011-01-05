require 'base_model'
require 'wikipedia_api'
require 'wikipedia_thing'

class WikipediaCategory < BaseModel
  identifier_path "categories"

  has :things, :collect => WikipediaThing

  def load
    data = WikipediaApi.page_info(:pageids => pageid)
    # FIXME: check that it really is a category

    return false if data.nil? or data.empty?
    update(data)

    data = WikipediaApi.category_members(title)
    data.each do |member|
      case member['ns']
        when 0
          self.things << WikipediaThing.new(member)
        else
          $stderr.puts "Unknown type of member: #{member.inspect}"
      end
    end

    true
  end

  def label
    @label ||= title.sub(/^Category:/,'')
  end

  def to_rdf
    RDF::Graph.new(doc_uri) do |graph|
      # Triples about the Document
      graph << [doc_uri, RDF.type, RDF::FOAF.Document]
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
