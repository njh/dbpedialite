#!/usr/bin/ruby

require 'thing'
require 'category'
require 'wikidata_api'
require 'extra_vocabs'


class DbpediaLite < Sinatra::Base
  set :public_folder, File.join(root, 'public')

  CANONICAL_HOST = 'www.dbpedialite.org'
  APP_LAST_UPDATED = File.mtime(root).gmtime
  GIT_LAST_COMMIT = ENV['COMMIT_HASH'] || `git rev-parse HEAD`

  FORMATS = [
    JSON::LD::Format,
    RDF::JSON::Format,
    RDF::NTriples::Format,
    RDF::RDFXML::Format,
    RDF::TriX::Format,
    RDF::Turtle::Format,
  ]

  def self.extract_vocabularies(graph)
    vocabs = {}
    graph.predicates.each do |predicate|
      RDF::Vocabulary.each do |vocab|
        if predicate.to_s.index(vocab.to_uri.to_s) == 0
          vocab_name = vocab.__name__.split('::').last.downcase
          unless vocab_name.empty?
            vocabs[vocab_name.to_sym] = vocab
            break
          end
        end
      end
    end
    vocabs
  end

  # FIXME: do proper content negotiation using Sinatra::Request::AcceptEntry
  # and Rack's MIME registry
  def negotiate_content(graph, format, html_view)
    if format.empty?
      format = request.accept.first.to_s || ''
      format.sub!(/;.+$/,'')
      headers 'Vary' => 'Accept'
    end

    case format
      when '', '*/*', 'html', 'application/xml', 'application/xhtml+xml', 'text/html' then
        content_type 'text/html'
        erb html_view
      when 'json', 'application/json', 'text/json' then
        content_type 'application/json'
        graph.dump(:json)
      when 'jsonld', 'application/ld+json' then
        content_type 'application/json'
        graph.dump(:jsonld, :standard_prefixes => true)
      when 'turtle', 'ttl', 'text/turtle', 'application/turtle' then
        content_type 'text/turtle'
        graph.dump(:turtle, :standard_prefixes => true)
      when 'nt', 'ntriples', 'application/n-triples', 'text/plain' then
        content_type 'text/plain'
        graph.dump(:ntriples)
      when 'rdf', 'rdfxml', 'application/rdf+xml', 'text/rdf' then
        content_type 'application/rdf+xml'
        graph.dump(:rdfxml, :standard_prefixes => true, :stylesheet => '/rdfxml.xsl')
      when 'trix', 'xml', 'application/trix' then
        content_type 'application/trix'
        graph.dump(:trix)
      else
        error 400, "Unsupported format: #{format}\n"
    end
  end

  def redirect_from_title(title)
    begin
      data = WikipediaApi.page_info(:titles => title)
      case data['ns']
        when 0 then
          redirect "/things/#{data['pageid']}", 301
        when 14 then
          redirect "/categories/#{data['pageid']}", 301
        else
          error 400, "Unsupported Wikipedia namespace: #{data['ns']}"
      end
    rescue MediaWikiApi::NotFound
      not_found "Wikipedia page title not found."
    rescue MediaWikiApi::Exception => e
      error 500, "Wikipedia API excpetion: #{e}"
    end
  end

  def redirect_from_wikidata(id)
    begin
      sitelink = WikidataApi.get_sitelink(id)
      redirect_from_title sitelink['title']
    rescue MediaWikiApi::NotFound => e
      not_found e.to_s
    rescue MediaWikiApi::Exception => e
      error 500, "Wikidata API excpetion: #{e}"
    end
    redirect_from_title(title)
  end

  helpers do
    include Sinatra::ContentFor
    include Sinatra::UrlForHelper

    def link_to(title, url=nil, attr={})
      url = title if url.nil?
      attr.merge!('href' => url.to_s)
      attr_str = attr.keys.map {|k| "#{h k}=\"#{h attr[k]}\""}.join(' ')
      "<a #{attr_str}>#{h title}</a>"
    end

    def nl2p(text)
      paragraphs = text.to_s.split(/[\n\r]+/)
      paragraphs.map {|para| "<p>#{para}</p>"}.join
    end

    def shorten(uri)
      qname = uri.qname.join(':') rescue uri.to_s
      escape_html(qname)
    end

    # Escape ampersands, brackets and quotes to their HTML/XML entities.
    def h(string)
      mapping = {
        "&" => "&amp;",
        "<" => "&lt;",
        ">" => "&gt;",
        "'" => "&#x27;",
        '"' => "&quot;"
      }
      pattern = /#{Regexp.union(*mapping.keys)}/n
      string.to_s.gsub(pattern){|c| mapping[c] }
    end

    def format_xmlns(vocabularies)
      if vocabularies
        xmlns = ''
        vocabularies.each_pair do |prefix,vocab|
          xmlns += " xmlns:#{h prefix}=\"#{h vocab.to_uri}\""
        end
        xmlns
      end
    end

    def truncate(text, len=30, truncate_string='...')
      return if text.nil?
      l = len - truncate_string.chars.count
      text.chars.count > len ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
    end

    def format_iso8061(datetime)
      datetime.strftime('%Y-%m-%dT%H:%M:%S%Z').sub(/\+00:00|UTC/, 'Z') unless datetime.nil?
    end

  end

  before do
    if settings.production? and request.host != CANONICAL_HOST
      headers 'Cache-Control' => 'public,max-age=86400'
      redirect "http://" + CANONICAL_HOST + request.path, 301
    end
    headers 'Access-Control-Allow-Origin' => '*'
  end

  get '/' do
    headers 'Cache-Control' => 'public,max-age=3600'
    @readme = RDiscount.new(File.read(File.join(File.dirname(__FILE__), 'README.md')))
    erb :index
  end

  get %r{/search\.?([a-z]*)} do |format|
    headers 'Cache-Control' => 'public,max-age=600'
    redirect '/' if params[:term].nil? or params[:term].empty?

    @results = WikipediaApi.search(params[:term], :srlimit => 20)
    @results.each do |result|
      result['url'] = "/titles/" + WikipediaApi.escape_title(result['title'])
    end

    case format
      when '', 'html' then
        erb :search
      when 'json' then
        json = []
        @results.each do |r|
          json << {:label => r['title']}
        end
        content_type 'text/json'
        json.to_json
      else
        error 400, "Unsupported format: #{format}\n"
    end
  end

  get '/titles/:title' do |title|
    headers 'Cache-Control' => 'public,max-age=600'
    redirect_from_title(title)
  end

  get %r{/wikidata/([qQ]\d+)} do |id|
    headers 'Cache-Control' => 'public,max-age=600'
    redirect_from_wikidata(id)
  end

  get %r{/things/([Qq]\d+)} do |id|
    headers 'Cache-Control' => 'public,max-age=600'
    redirect_from_wikidata(id)
  end

  get %r{/things/(\d+)\.?([a-z0-9]*)} do |pageid,format|
    headers 'Cache-Control' => 'public,max-age=600'
    begin
      @thing = Thing.load(pageid)
    rescue WikipediaApi::Redirect => redirect
      redirect("/things/#{redirect.pageid}", 301)
    rescue MediaWikiApi::NotFound
      not_found("Thing not found.")
    end

    @thing.doc_uri = request.url
    @graph = @thing.to_rdf
    @vocabularies = DbpediaLite.extract_vocabularies(@graph)

    negotiate_content(@graph, format, :thing)
  end

  get %r{/categories/(\d+)\.?([a-z0-9]*)} do |pageid,format|
    headers 'Cache-Control' => 'public,max-age=600'
    begin
      @category = Category.load(pageid)
    rescue WikipediaApi::Redirect => redirect
      redirect("/categories/#{redirect.pageid}", 301)
    rescue MediaWikiApi::NotFound
      not_found("Category not found.")
    end

    @category.doc_uri = request.url
    @graph = @category.to_rdf
    @vocabularies = DbpediaLite.extract_vocabularies(@graph)

    negotiate_content(@graph, format, :category)
  end

  get '/gems' do
    headers 'Cache-Control' => 'public,max-age=3600'
    @specs = Gem::loaded_specs.values.sort {|a,b| a.name <=> b.name }
    erb :gems
  end

  get '/flipr' do
    headers 'Cache-Control' => 'public,max-age=600'
    redirect "/", 301 if params[:url].nil? or params[:url].empty?

    if params[:url] =~ %r{^https?://(\w+)\.wikipedia.org/wiki/(.+)(\#\w*)?$}
      redirect_from_title($2)
    elsif params[:url] =~ %r{^https?://dbpedia.org/(page|resource|data)/(.+)$}
      redirect_from_title($2)
    elsif params[:url] =~ %r{^https?://(www\.)?wikidata.org/(wiki|entity)/(Q\d+)$}
      redirect_from_wikidata($3)
    elsif params[:url] =~ %r{^https?://www.freebase.com/(view|inspect|edit/topic)(/.+)$}
      begin
        data = FreebaseApi.lookup_by_id($2)
        redirect "/things/#{data['key']['value']}", 301
      rescue FreebaseApi::NotFound
        not_found("No Wikipedia page id found for Freebase topic")
      end
    elsif params[:url] =~ %r{^https?://([\w\.\-\:]+)/(things|categories)/(\d+)(\#\w*)?$}
      begin
        data = WikipediaApi.page_info(:pageids => $3)
        escaped = WikipediaApi.escape_title(data['title'])
        redirect "http://en.wikipedia.org/wiki/#{escaped}", 301
      rescue MediaWikiApi::NotFound
        not_found("Wikipedia page id not found")
      end
    else
      erb :flipfail
    end
  end

end
