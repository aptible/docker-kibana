#!/usr/bin/env bash

ES_HOST="$($DATABASE_URL | cut -d = -f 2 | cut -d@ -f 2 | cut -d : -f 1)"
ES_PORT="$($DATABASE_URL | cut -d = -f 2 | cut -d@ -f 2 | cut -d : -f 2)"
ES_AUTH="$($DATABASE_URL | cut -d = -f 2 | cut -d@ -f 1 | cut -d / -f 3)"

echo >> etc/crontab "20 0 * * * /usr/local/bin/curator --host $ES_HOST --port $ES_PORT --http_auth $ES_AUTH --use_ssl --ssl-no-validate close indices --older-than 90 --time-unit days --timestring '%Y.%m.%d'"

echo >> etc/crontab "25 0 * * * /usr/local/bin/curator --host $ES_HOST --port $ES_PORT --http_auth $ES_AUTH --use_ssl --ssl-no-validate delete indices --older-than 120 --time-unit days --timestring '%Y.%m.%d'"

echo 'crontab created'

exit 0
