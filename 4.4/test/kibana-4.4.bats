#!/usr/bin/env bats

source /tmp/test/shared.sh

teardown() {
  cleanup
}

HTTP_RESPONSE_HEAD="HTTP/1.1 200 OK

"


@test "docker-kibana proxies with credentials to Elasticsearch 2.x" {

  web_log="${BATS_TEST_DIRNAME}/web.log"
  ( while echo "$HTTP_RESPONSE_HEAD" '{"version": {"number": "2.2.0"}}' | nc -l 456; do : ; done ) > "$web_log" &
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://user:pass@localhost:456 /bin/bash run-kibana.sh &
  # Hit Kibana directly on port 5601
  until curl "localhost:5601/elasticsearch/twitter/_search"; do
    echo "Waiting for Kibana to come online"
    sleep 1
  done

  sleep 1
  pkill node
  pkill nc

  # Check that a authorization header was sent to "Elasticsearch"
  grep -A8 "twitter/_search" "$web_log" | grep -i "Authorization: Basic"
}

@test "docker-kibana detects supported Elasticsearch for kibana:${KIBANA_VERSION}" {
  echo '{"version": {"number": "2.2.1"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  /bin/bash check-es-version.sh http://localhost:456
}

@test "docker-kibana detects incompatible Elasticsearch versions" {
  echo '{"version": {"number": "1.0"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  run /bin/bash check-es-version.sh http://localhost:456
  [ $(expr "$output" : ".*using the right image: aptible/kibana:4.1") -ne 0 ]
}
