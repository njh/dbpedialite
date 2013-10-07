class Dbpedialite
  FORMATS = [
    {
      :name => 'JSON',
      :mime => 'application/json',
      :suffix => 'json'
    },
    {
      :name => 'JSON-LD',
      :mime => 'application/ld+json',
      :suffix => 'jsonld'
    },
    {
      :name => 'Turtle',
      :mime => 'text/turtle',
      :suffix => 'ttl'
    },
    {
      :name => 'N-Triples',
      :mime => 'text/plain',
      :suffix => 'nt'
    },
    {
      :name => 'RDF/XML',
      :mime => 'application/rdf+xml',
      :suffix => 'rdf'
    },
    {
      :name => 'TriX',
      :mime => 'application/trix',
      :suffix => 'trix'
    }
  ]
end
