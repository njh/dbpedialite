#!/bin/sh

set -e

bundle install --deployment
bundle exec rake spec
