#!/bin/bash
#shellcheck disable=SC2086
{
  : ${AUTH_CREDENTIALS:?"Error: environment variable AUTH_CREDENTIALS should be populated with a comma-separated list of user:password pairs. Example: \"admin:pa55w0rD\"."}
  : ${DATABASE_URL:?"Error: environment variable DATABASE_URL should be set to the Aptible DATABASE_URL of the Elasticsearch instance you wish to use."}
}

# Parse auth credentials, add to a htpasswd file.
AUTH_PARSER="
create_opt = 'c'
ENV['AUTH_CREDENTIALS'].split(',').map do |creds|
  user, password = creds.split(':')
  %x(htpasswd -b#{create_opt} /etc/nginx/conf.d/kibana.htpasswd #{user} #{password})
  create_opt = ''
end"

ruby -e "$AUTH_PARSER" || {
  echo "Error creating htpasswd file from credentials '$AUTH_CREDENTIALS'"
  exit 1
}

erb -T 2 -r uri -r base64 ./kibana.erb > /etc/nginx/sites-enabled/kibana || {
  echo "Error creating nginx configuration from Elasticsearch url '$DATABASE_URL'"
  exit 1
}

# If we don't have a version set, then try to guess one form the Elasticsearch server.
if [[ -z "$KIBANA_ACTIVE_VERSION" ]]; then
  KIBANA_VERSION_PARSER="
  require 'json'
  version = JSON.parse(STDIN.read)['version']['number']
  print 41 if version.start_with?('1.')
  print 44 if version.start_with?('2.')
  print 5 if version.start_with?('5.')"
  KIBANA_ACTIVE_VERSION="$(curl "$DATABASE_URL" 2>/dev/null | ruby -e "$KIBANA_VERSION_PARSER" 2>/dev/null)"
fi

# If we still don't have a version, fall back to the default.
if [[ -z "$KIBANA_ACTIVE_VERSION" ]]; then
    echo "Warning: unable to fetch Elasticsearch version, and none configured. Defaulting to 5.x. Consider setting KIBANA_ACTIVE_VERSION."
    KIBANA_ACTIVE_VERSION="5"
fi

echo "KIBANA_ACTIVE_VERSION is set to: '$KIBANA_ACTIVE_VERSION'"

KIBANA_VERSION_PTR="KIBANA_${KIBANA_ACTIVE_VERSION}_VERSION"
KIBANA_VERSION="${!KIBANA_VERSION_PTR}"

# Run config
erb -T 2 -r uri "/opt/kibana-${KIBANA_VERSION}/config/kibana.yml.erb" > "/opt/kibana-${KIBANA_VERSION}/config/kibana.yml" || {
  echo "Error creating kibana config file"
  exit 1
}

service nginx start

# Default node options to limit Kibana memory usage as per https://github.com/elastic/kibana/issues/5170
# If this is not set, Node tries to use about 1.5GB of memory before it starts actively garbage collect.
# shellcheck disable=SC2086
: ${NODE_OPTIONS:="--max-old-space-size=256"}

export NODE_OPTIONS
exec "/opt/kibana-${KIBANA_VERSION}/bin/kibana"
