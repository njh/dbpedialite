$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
$:.unshift(File.join(File.dirname(__FILE__),'..'))

require 'rubygems'
require 'bundler'

Bundler.require(:default, :test)

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.before(:each) do
    FakeWeb.clean_registry
  end
end

FakeWeb.allow_net_connect = false

def fixture(filename)
  File.join(File.dirname(__FILE__),'fixtures',filename)
end

def fixture_data(filename)
  File.read(fixture(filename))
end

