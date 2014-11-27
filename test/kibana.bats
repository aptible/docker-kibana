#!/usr/bin/env bats

teardown() {
  service nginx stop
  rm /etc/nginx/conf.d/kibana.htpasswd || true
  rm /etc/nginx/sites-enabled/kibana || true
  rm /var/log/nginx/access.log || true
  rm /var/log/nginx/error.log || true
  pkill tcpserver || true
}

@test "docker-kibana should use Kibana v3.1.2" {
  run grep -F "kibana - v3.1.2" /opt/kibana-3.1.2/app/app.js
  [ "$status" -eq 0 ]
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

@test "docker-kibana returns results if basic auth credentials are provided over https" {
  XFP="X-Forwarded-Proto: https"
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://localhost timeout 1 /bin/bash run-kibana.sh || true
  run curl -I -H "$XFP" http://root:admin123@localhost
  [ "$status" -eq 0 ]
  [[ "$output" =~ "HTTP/1.1 200 OK" ]]
}

@test "docker-kibana correctly proxies calls to an Elasticsearch backend based on DATABASE_URL" {
  XFP="X-Forwarded-Proto: https"
  AUTH_CREDENTIALS=root:pwd DATABASE_URL=http://a:b@localhost:1234 timeout 1 /bin/bash run-kibana.sh || true
  RESPONSE="HTTP/1.1 200 OK\nContent-Type: text/html\nContent-Length: 29\n\nHello from mock Elasticsearch"
  tcpserver 127.0.0.1 1234 sh -c "echo \"$RESPONSE\" && sleep 1" &
  run curl -H "$XFP" http://root:pwd@localhost/_nodes
  [[ "$output" =~ "Hello from mock Elasticsearch" ]]
}
