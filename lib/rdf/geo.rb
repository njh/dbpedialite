module RDF
  ##
  # WGS84 Geo Positioning vocabulary.
  #
  # @see http://www.w3.org/2003/01/geo/wgs84_pos
  class GEO < Vocabulary('http://www.w3.org/2003/01/geo/wgs84_pos#')
    property :SpatialThing
    property :Point
    property :lat
    property :location
    property :long
    property :alt
    property :lat_long
  end
end
