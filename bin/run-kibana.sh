#!/bin/bash
#shellcheck disable=SC2086
{
  : ${FORCE_SSL:?"Error: environment variable FORCE_SSL should be set to ensure HTTPS only access."}
  : ${OAUTH2_PROXY_CLIENT_ID:?"Error: environment variable OAUTH2_PROXY_CLIENT_ID should be set to the oauth provider's CLIENT ID."}
  : ${OAUTH2_PROXY_CLIENT_SECRET:?"Error: environment variable OAUTH2_PROXY_CLIENT_SECRET should be set to the oauth provider's CLIENT SECRET"}
  : ${OAUTH2_PROXY_COOKIE_SECRET:?"Error: environment variable OAUTH2_PROXY_COOKIE_SECRET should be set to either 8, 16, or 32 byte string."}
  : ${DATABASE_URL:?"Error: environment variable DATABASE_URL should be set to the Aptible DATABASE_URL of the Elasticsearch instance you wish to use."}
}

# Run oauth2 proxy
# Oauth2 proxy by default listens for certain env var (e.g. OAUTH2_PROXY_CLIENT_ID)
# The complete list can be found on
# https://github.com/bitly/oauth2_proxy#environment-variables
/opt/oauth2_proxy/oauth2_proxy -provider=github \
                               -upstream=http://127.0.0.1:5601 \
                               -login-url=https://github.com/login/oauth/authorize \
                               -cookie-httponly=true \
                               -cookie-secure=true \
                               -http-address="0.0.0.0:80" \
                               -email-domain=* \
                               -github-team=$GITHUB_TEAMS \
                               -github-org=$GITHUB_ORG \
                               -redirect-url=$OAUTH2_PROXY_REDIRECT_URL &

# If we don't have a version set, then try to guess one form the Elasticsearch server.
if [[ -z "$KIBANA_ACTIVE_VERSION" ]]; then
  KIBANA_VERSION_PARSER="
  require 'json'
  version = JSON.parse(STDIN.read)['version']['number']
  print version.start_with?('1.') ? 41 : 44"
  KIBANA_ACTIVE_VERSION="$(curl "$DATABASE_URL" 2>/dev/null | ruby -e "$KIBANA_VERSION_PARSER" 2>/dev/null)"
fi

# If we still don't have a version, fall back to the default.
if [[ -z "$KIBANA_ACTIVE_VERSION" ]]; then
    echo "Warning: unable to fetch Elasticsearch version, and none configured. Defaulting to 4.4. Consider setting KIBANA_ACTIVE_VERSION."
    KIBANA_ACTIVE_VERSION="44"
fi

echo "KIBANA_ACTIVE_VERSION is set to: '$KIBANA_ACTIVE_VERSION'"

KIBANA_VERSION_PTR="KIBANA_${KIBANA_ACTIVE_VERSION}_VERSION"
KIBANA_VERSION="${!KIBANA_VERSION_PTR}"

# Run config
erb -T 2 -r uri "/opt/kibana-${KIBANA_VERSION}/config/kibana.yml.erb" > "/opt/kibana-${KIBANA_VERSION}-linux-x64/config/kibana.yml" || {
  echo "Error creating kibana config file"
  exit 1
}

exec "/opt/kibana-${KIBANA_VERSION}-linux-x64/bin/kibana"