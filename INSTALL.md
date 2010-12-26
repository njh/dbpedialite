# Installing dbpedialite on your machine

Clone the repo from github:
 
    git clone git://github.com/njh/dbpedialite.git
    cd dbpedialite

Install the required gems using bundler:

    bundle install

Start the application:
 
    bundle exec rackup -p 4567

Visit the application in your browser at http://localhost:4567/


To run the tests you'll also need the [Raptor
RDF](http://librdf.org/raptor/rapper.html) parser. A simple way to
install this on Mac OS X is using
[homebrew](http://github.com/mxcl/homebrew)

    brew install raptor

Or using [fink](http://fink.sf.net/):

    fink install raptor

Or on [Debian GNU/Linux](http://www.debian.org/):

    apt-get install raptor


You can then run the tests using:

    bundle exec rake spec
