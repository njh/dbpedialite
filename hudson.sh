#!/bin/sh

set -e
set -x

BUNDLE="bundle --no-color"

$BUNDLE install --deployment
$BUNDLE exec rake spec
