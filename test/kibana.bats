#!/usr/bin/env bats

teardown() {
  pkill tcpserver || true
  pkill nc || true
  rm -f "/opt/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml"
  rm -f "/opt/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
}

@test "docker-kibana requires the DATABASE_URL environment variable to be set" {
  export AUTH_CREDENTIALS=foobar
  run timeout 1 /bin/bash run-kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "DATABASE_URL" ]]
}

@test "docker-kibana requires the FORCE_SSL environment variable to be set" {
  export AUTH_CREDENTIALS=foobar
  run timeout 1 /bin/bash run-kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "FORCE_SSL" ]]
}

@test "docker-kibana requires the OAUTH2_PROXY_CLIENT_ID environment variable to be set" {
  export AUTH_CREDENTIALS=foobar
  run timeout 1 /bin/bash run-kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "OAUTH2_PROXY_CLIENT_ID" ]]
}

@test "docker-kibana requires the OAUTH2_PROXY_CLIENT_SECRET environment variable to be set" {
  export AUTH_CREDENTIALS=foobar
  run timeout 1 /bin/bash run-kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "OAUTH2_PROXY_CLIENT_SECRET" ]]
}

@test "docker-kibana requires the OAUTH2_PROXY_COOKIE_SECRET environment variable to be set" {
  export AUTH_CREDENTIALS=foobar
  run timeout 1 /bin/bash run-kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "OAUTH2_PROXY_COOKIE_SECRET" ]]
}

@test "docker-kibana sets the elasticsearch url correctly for Kibana 4.1.x" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=41 timeout 1 /bin/bash run-kibana.sh || true
  run grep "elasticsearch_url: \"http://root:admin123@localhost:1234\"" "opt/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "docker-kibana sets the elasticsearch username correctly for Kibana 4.1.x" {
 AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=41 timeout 1 /bin/bash run-kibana.sh || true
 run grep "kibana_elasticsearch_username: \"root\"" "opt/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml"
 [ "$status" -eq 0 ]
}

@test "docker-kibana sets the elasticsearch password correctly for Kibana 4.1.x" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=41 timeout 1 /bin/bash run-kibana.sh || true
  run grep "kibana_elasticsearch_password: \"admin123\"" "opt/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "docker-kibana sets the elasticsearch url correctly for Kibana 4.4.x" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=44 timeout 1 /bin/bash run-kibana.sh || true
  run grep "elasticsearch.url: \"http://root:admin123@localhost:1234\"" "opt/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "docker-kibana sets the elasticsearch username correctly for Kibana 4.4.x" {
 AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=44 timeout 1 /bin/bash run-kibana.sh || true
 run grep "elasticsearch.username: \"root\"" "opt/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
 [ "$status" -eq 0 ]
}

@test "docker-kibana sets the elasticsearch password correctly for Kibana 4.4.x" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=44 timeout 1 /bin/bash run-kibana.sh || true
  run grep "elasticsearch.password: \"admin123\"" "opt/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "docker-kibana detects Elasticsearch 1.x" {
  # Kibana will actually fail to start here, because "Elasticsearch" will go down after the initial request,
  # but it doesn't really matter: we're only checking which configuration files get created.
  echo "$HTTP_RESPONSE_HEAD" '{"version": {"number": "1.5.2"}}' | nc -l 456 &
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://localhost:456 run timeout 1 /bin/bash run-kibana.sh
  [[ ! -f "/opt/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml" ]]
  [[ -f "/opt/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml" ]]
}

@test "docker-kibana detects Elasticsearch 2.x" {
  # Same notes as above.
  echo "$HTTP_RESPONSE_HEAD" '{"version": {"number": "2.2.0"}}' | nc -l 456 &
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://localhost:456 run timeout 1 /bin/bash run-kibana.sh
  [[ -f "/opt/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml" ]]
  [[ ! -f "/opt/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml" ]]
}
