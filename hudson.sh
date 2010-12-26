#!/bin/sh

set -e
set -x

bundle install --deployment
bundle exec rake spec
