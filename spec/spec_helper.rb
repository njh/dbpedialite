$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
$:.unshift(File.join(File.dirname(__FILE__),'..'))

require 'rubygems'
require 'spira'
require 'spec'
require 'mocha'
require 'rack/test'

Spira.add_repository! :default, RDF::Repository.new


def fixture(filename)
  File.join(File.dirname(__FILE__),'fixtures',filename)
end

def fixture_data(filename)
  File.read(fixture(filename))
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.include Rack::Test::Methods
end
