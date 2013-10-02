#!/usr/bin/env ruby
#
# Experimental script to ping sindice when
# a wikipedia article changes.
#
#

$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'rubygems'
require 'IRC'
require 'json'
require 'logger'
require 'wikipedia_api'

Thread.abort_on_exception = true

class WikipediaUpdater
  attr_accessor :logger
  USER_AGENT = 'Dbpedialite/1'
  HTTP_TIMEOUT = 5

  def initialize
    @logger = Logger.new(STDOUT)
  end

  def ping_sindice(data)
    uri = URI.parse("http://api.sindice.com/v2/ping")
    begin
      req = Net::HTTP::Post.new(uri.request_uri)
      req['User-Agent'] = USER_AGENT
      req['Content-Type'] = 'text/plain'
      req['Content-Length'] = data.length
      req['Accept'] = 'text/plain'
      req.body = data

      res = Net::HTTP.start(uri.host, uri.port) do |http|
        http.read_timeout = HTTP_TIMEOUT
        http.open_timeout = HTTP_TIMEOUT
        http.request(req)
      end
      raise res.body unless res.code == '200'
      puts "Sindice Response: #{res.body}"
    rescue Exception => e
      puts "Failed to ping sindice: #{e}"
    end
  end


  def run
    mutex = Mutex.new
    last_message_time = Time.now

    @irc_queue = Queue.new
    @uri_queue = Queue.new

    @irc_thread = Thread.new(@irc_queue) do |iq|
      bot = IRC.new('dbpedialite', "irc.wikimedia.org", 6667, "dbpedia lite")
      IRCEvent.add_callback('endofmotd') { |event| bot.add_channel('#en.wikipedia') }
      IRCEvent.add_callback('nicknameinuse') { |event| STDERR.puts event.message; exit(1) }
      IRCEvent.add_callback('privmsg') do |event|
        # add the message to the queue as soon as it is received
        iq.enq event.message
        # update the last message time so it can be monitored
        mutex.synchronize { last_message_time = Time.now }
      end
      bot.connect
    end

    # check that we are getting regular updates
    @monitor_thread = Thread.new do
      begin
        sleep 30
        age = nil
        mutex.synchronize { age = (Time.now - last_message_time) }
      end while (age < 30)
      STDERR.puts "Exiting: it's over 30 seconds since we've received a message at #{last_message_time}"
      exit(1)
    end

    @resolver_thread = Thread.new(@irc_queue, @uri_queue) do |iq, uq|
      loop do
        # retrive a message from the irc queue
        message = iq.deq

        # remove mirc colours
        message.gsub!(/\cc\d{1,2}|\cc/, '')

        # extract title from irc message
        title = $1 if message=~/\[\[(.*?)\]\]/
        next unless title

        # Ignore special and talk pages
        next if title =~ /^(\w+|\w+ talk):/

        # Lookup the page id
        data = WikipediaApi.page_info(:titles => title)
        next if data.nil?

        # Display status
        printf("[%s] %2d %9d: %s\n", iq.length, data['ns'], data['pageid'], data['title'])

        # Enqueue the URI for submission
        if data['ns'] == 0
          uq.enq "http://www.dbpedialite.org/things/#{data['pageid']}.rdf"
        else
          puts "Unknown namespace for #{title}"
        end
      end
    end

    @submission_thread = Thread.new(@uri_queue) do |uq|
      loop do
        sleep 60

        # De-queue all the URIs
        uris = []
        while uq.length > 0
          uris << uq.pop
        end
        uris.uniq!

        unless uris.empty?
          ping_sindice uris.join("\n")
        end
      end
    end


    [@irc_thread, @monitor_thread, @resolver_thread, @submission_thread].each { |t| t.join }
  end
end


updater = WikipediaUpdater.new
updater.run
