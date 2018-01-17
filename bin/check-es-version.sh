#!/bin/bash
#shellcheck disable=SC2086
set -o errexit
set -o nounset
set -o pipefail

DATABASE_URL="$1"

function wait_for_request {
  for _ in {1..10}; do
    if curl -f "$DATABASE_URL" > /dev/null 2>&1; then
      return 0
    else
      sleep 1
    fi
  done

  printf "! ! ! ! ! !\n  Unable to reach Elasticsearch server, please check DATABASE_URL and your database server. \n ! ! ! ! ! !"
  return 1
}


#Check that we're using the right Kibana version for the ES we're connecting to

KIBANA_VERSION_PARSER="
require 'json'
es_version = JSON.parse(STDIN.read)['version']['number']
print 4.1 if es_version.start_with?('1.')
print 4.4 if es_version.start_with?('2.')
print 5.0 if es_version.start_with?('5.0.')
print 5.1 if es_version.start_with?('5.1.')
print 6.0 if es_version.start_with?('6.0.')
print 6.1 if es_version.start_with?('6.1.')"

wait_for_request

KIBANA_NEEDED_VERSION="$(curl -fsSL "$DATABASE_URL" | ruby -e "$KIBANA_VERSION_PARSER")" 

if [[ -z "$KIBANA_NEEDED_VERSION" ]]; then
  printf "! ! ! ! ! !\n Not an Elasticsearch server, or your version of Elasticsearch not supported by this application. \n ! ! ! ! ! !"
  exit 1
fi

if [[ "$TAG" != "$KIBANA_NEEDED_VERSION" ]]; then
  printf "! ! ! ! ! !\n You're using aptible/kibana:${TAG}, which is not compatible with your version of Elasticsearch,"
  printf "you need to use aptible/kibana:${KIBANA_NEEDED_VERSION} ! ! ! ! ! !"
  exit 1
fi
