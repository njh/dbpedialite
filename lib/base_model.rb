require 'uri'

class BaseModel
  attr_accessor :identifier
  attr_accessor :title

  def initialize(identifier, args={})
    @identifier = identifier
    assign(args) unless args.empty?
  end

  def self.load(identifier)
    object = self.new(identifier)
    object.load ? object : nil
  end

  def self.base_uri(uri)
    @@base_uri = uri
  end

  def self.identifier_type(type)
    @@identifier_type = type
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
    @uri ||= RDF::URI.parse("#{@@base_uri}/#{identifier}##{@@identifier_type}")
  end

  def doc_uri=(uri)
    @doc_uri = RDF::URI.parse(uri.to_s)
  end

  def doc_uri(format=nil)
    if format
      doc_uri + ".#{format}"
    else
      @doc_uri || RDF::URI.parse("#{@@base_uri}/#{identifier}")
    end
  end

  def escaped_title
    unless title.nil?
      URI::escape(title.gsub(' ','_'), ',')
    end
  end

  def wikipedia_uri
    @wikipedia_uri ||= RDF::URI.parse("http://en.wikipedia.org/wiki/#{escaped_title}")
  end

  def dbpedia_uri
    @dbpedia_uri ||= RDF::URI.parse("http://dbpedia.org/resource/#{escaped_title}")
  end
end
