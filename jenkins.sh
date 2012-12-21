#!/usr/bin/env bash

set -e
set -x

eval "$(rbenv init -)"
rbenv local 1.8.7-p358

bundle install --deployment --path=.bundle/gems
bundle exec rake spec
