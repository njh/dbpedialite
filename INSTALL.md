# Installing dbpedialite on your machine

Clone the repo from github:
 
    git clone git://github.com/njh/dbpedialite.git
    cd dbpedialite

Install the required gems using [bundler](http://gembundler.com/):

    bundle install

Start the application:
 
    bundle exec rackup -p 4567

Or use shotgun, which causes the app to reload after every request:

    bundle exec shotgun -p 4567

Visit the application in your browser at:
[http://localhost:4567/](http://localhost:4567/)

You can then run the tests using:

    bundle exec rake spec
