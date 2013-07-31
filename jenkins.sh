#!/usr/bin/env bash

set -e
set -x

rbenv version
ruby -v

bundle install --deployment --path=.bundle/gems
bundle exec rake spec
