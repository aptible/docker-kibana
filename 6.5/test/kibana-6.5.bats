#!/usr/bin/env bats

source /tmp/test/shared.sh

teardown() {
  cleanup
}

@test "docker-kibana detects supported Elasticsearch for kibana:${KIBANA_VERSION}" {
  echo '{"version": {"number": "'"${KIBANA_VERSION}"'"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  /bin/bash check-es-version.sh http://localhost:456
}

@test "docker-kibana detects incompatible Elasticsearch versions" {
  echo '{"version": {"number": "1.0"}}' > /tmp/test/index.html
  ( cd /tmp/test/ && busybox httpd -f -p '127.0.0.1:456' ) &
  run /bin/bash check-es-version.sh http://localhost:456
  [ $(expr "$output" : ".*using the right image: aptible/kibana:4.1") -ne 0 ]
}
