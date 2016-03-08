#!/bin/bash
#shellcheck disable=SC2086
{
  : ${DATABASE_URL:?"Error: environment variable DATABASE_URL should be set to the Aptible DATABASE_URL of the Elasticsearch instance you wish to use."}
}

# Run oath2_plugin
/opt/oauth2_proxy/oauth2_proxy -client-id=$GITHUB_CLIENT_ID \
                              -client-secret=$GITHUB_SECRET \
                              -provider=github \
                              -upstream=http://127.0.0.1:5601 \
                              -cookie-secret=ugivXaBhREZKdLZN9XJNb8dLuRmXfV \
                              -login-url=https://github.com/login/oauth/authorize \
                              -cookie-httponly=true \
                              -cookie-secure=false \
                              -http-address="0.0.0.0:80" \
                              -email-domain=* \
                              -github-team=$GITHUB_TEAMS \
                              -github-org=$GITHUB_ORG \
                              -version=false \
                              -cookie-expire=$OAUTH_COOKIE_EXPIRATION \
                              -redirect-url=$OAUTH_REDIRECT_URL &

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