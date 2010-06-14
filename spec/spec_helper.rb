$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
$:.unshift(File.join(File.dirname(__FILE__),'..'))

require 'rubygems'
require 'spira'
require 'spec'
require 'mocha'

Spira.add_repository! :default, RDF::Repository.new


def fixture(filename)
  File.join(File.dirname(__FILE__),'fixtures',filename)
end

def fixture_data(filename)
  File.read(fixture(filename))
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

def mock_http(host, fixture_filename)
  response = stub(
    :value => nil,
    :body => fixture_data(fixture_filename)
  )
  Net::HTTP.expects(:start).with(host,80).once.returns(response)
end

# FIXME: setup mock to never expect HTTP requests
