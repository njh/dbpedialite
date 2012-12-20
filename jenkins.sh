#!/bin/sh

set -e
set -x

eval "$(rbenv init -)"
rbenv local 1.8.7-debian

bundle install --deployment --path=.bundle/gems
bundle exec rake spec
