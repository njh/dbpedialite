source "https://rubygems.org"
ruby File.read('.ruby-version').chomp

gem 'thin'

gem 'sinatra'
gem 'sinatra-contrib', :require => 'sinatra/content_for'
gem 'emk-sinatra-url-for', :require => 'sinatra/url_for'

gem 'json_pure', :require => 'json'
gem 'nokogiri'
gem 'rdiscount'
gem 'doodle'

gem 'rdf', "~>1.0.8"
gem 'rdf-json', "~>1.0.0", :require => 'rdf/json'
gem 'rdf-turtle', "~>1.0.9", :require => 'rdf/turtle'
gem 'rdf-trix', "~>1.0.0", :require => 'rdf/trix'
gem 'rdf-rdfxml', "~>1.0.2"
gem 'json-ld', "~>1.0.7"

group :development do
  gem 'rake'
  gem 'shotgun'
end

group :test do
  gem 'rspec', '>=2.7.0'
  gem 'fakeweb'
  gem 'simplecov'
  gem 'rack-test', :require => 'rack/test'
  gem 'rdf-rdfa', :require => 'rdf/rdfa'
  gem 'equivalent-xml'
end
