#!/bin/bash
#shellcheck disable=SC2086

{
  : ${DATABASE_URL:?"Error: environment variable DATABASE_URL must be set to the Aptible DATABASE_URL of the Elasticsearch instance you wish to use."}
}

if [ -n "$AUTH_CREDENTIALS" ]; then
	echo "Error: AUTH_CREDENTIALS are not used for authentication in this image. Authentication is handled by Elasticsearch security."
	echo "Remove this variable to continue (`aptible config:unset $HANDLE AUTH_CREDENTIALS`)"
	exit 1
fi

# Run config
erb -T 2 -r uri -r base64 "/opt/kibana/config/kibana.yml.erb" > "/opt/kibana/config/kibana.yml" || {
  echo "Error creating kibana config file"
  exit 1
}

# Default node options to limit Kibana memory usage as per https://github.com/elastic/kibana/issues/5170
# If this is not set, Node tries to use about 1.5GB of memory before it starts actively garbage collect.
# shellcheck disable=SC2086
: ${NODE_OPTIONS:="--max-old-space-size=256"}

export NODE_OPTIONS
exec "/opt/kibana/bin/kibana" "--allow-root"
