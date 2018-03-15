#!/usr/bin/env bats

source /tmp/test/shared.sh

teardown() {
  cleanup
}

@test "docker-kibana requires the AUTH_CREDENTIALS environment variable to be set" {
  export DATABASE_URL=foobar
  run timeout 1 /bin/bash run-kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "AUTH_CREDENTIALS" ]]
}

@test "docker-kibana requires the DATABASE_URL environment variable to be set" {
  export AUTH_CREDENTIALS=foobar
  run timeout 1 /bin/bash run-kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "DATABASE_URL" ]]
}

@test "docker-kibana redirects any http requests permanently to https" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://localhost timeout 1 /bin/bash run-kibana.sh || true
  REDIRECT_301="301 Moved Permanently"
  run bash -c 'curl http://localhost | grep "$REDIRECT_301" && \
               curl http://localhost/_aliases | grep "$REDIRECT_301" && \
               curl http://localhost/foo/_aliases | grep "$REDIRECT_301" && \
               curl http://localhost/_nodes | grep "$REDIRECT_301" && \
               curl http://localhost/foobar/_search | grep "$REDIRECT_301" && \
               curl http://localhost/foobar/_mapping | grep "$REDIRECT_301" && \
               curl http://localhost/kibana-int/dashboard/foo | grep "$REDIRECT_301" && \
               curl http://localhost/kibana-int/tempfoo | grep "$REDIRECT_301"'
  [ "$status" -eq 0 ]
}

@test "docker-kibana protects all pages with basic auth" {
  XFP="X-Forwarded-Proto: https"
  ERROR_401="401 Authorization Required"
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://localhost timeout 1 /bin/bash run-kibana.sh || true
  run bash -c 'curl -H "$XFP" http://localhost | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/_aliases | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/foo/_aliases | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/_nodes | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/foobar/_search | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/foobar/_mapping | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/kibana-int/dashboard/foo | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/kibana-int/tempfoo | grep "$ERROR_401"'
  [ "$status" -eq 0 ]
}


case ${TAG} in  
  4.1)
    ES_URL_KEY=elasticsearch_url
    ES_USERNAME_KEY=kibana_elasticsearch_username
    ES_PASSWORD_KEY=kibana_elasticsearch_password
    ;;
  *)
    ES_URL_KEY=elasticsearch.url
    ES_USERNAME_KEY=elasticsearch.username
    ES_PASSWORD_KEY=elasticsearch.password
    ;;
esac

@test "docker-kibana sets the elasticsearch url correctly" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 timeout 1 /bin/bash run-kibana.sh || true
  run grep "${ES_URL_KEY}: \"http://root:admin123@localhost:1234\"" "opt/kibana/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "docker-kibana sets the elasticsearch username correctly" {
 AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 timeout 1 /bin/bash run-kibana.sh || true
 run grep "${ES_USERNAME_KEY}: \"root\"" "opt/kibana/config/kibana.yml"
 [ "$status" -eq 0 ]
}

@test "docker-kibana sets the elasticsearch password correctly" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 timeout 1 /bin/bash run-kibana.sh || true
  run grep "${ES_PASSWORD_KEY}: \"admin123\"" "opt/kibana/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "docker-kibana detects unsupported Elasticsearch versions" {
  echo '{"version": {"number": "0.8"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  run /bin/bash check-es-version.sh http://localhost:456
  [ $(expr "$output" :  ".*supported Elasticsearch server") -ne 0 ]
}

@test "docker-kibana detects inability to connect to Elasticsearch" {
  run /bin/bash check-es-version.sh http://localhost:456
  [ $(expr "$output" : ".*Unable to reach Elasticsearch server") -ne 0 ]
}
