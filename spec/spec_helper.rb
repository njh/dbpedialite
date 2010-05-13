$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))

require 'rubygems'
require 'spec'
require 'mocha'

def fixture(filename)
  File.join(File.dirname(__FILE__),'fixtures',filename)
end

def fixture_data(filename)
  File.read(fixture(filename))
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
end
