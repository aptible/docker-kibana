#!/usr/bin/env bats

source /tmp/test/shared.sh

teardown() {
  cleanup
}

@test "It should install Kibana 4.1.1" {
  run /opt/kibana/bin/kibana --version
  [[ "$output" =~ "4.1.1"  ]]
}

@test "docker-kibana detects supported Elasticsearch for kibana:${KIBANA_VERSION}" {
  echo '{"version": {"number": "1.5.2"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  /bin/bash check-es-version.sh http://localhost:456
}

@test "docker-kibana detects incompatible Elasticsearch versions" {
  echo '{"version": {"number": "2.0"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  run /bin/bash check-es-version.sh http://localhost:456
  [ $(expr "$output" : ".*you need to use aptible/kibana:4.4") -ne 0 ]
}