#!/bin/bash
set -o errexit
set -o nounset

IMG="$1"
TAG="$2"

case "$TAG" in
  4.1 )
    echo "Skipping for Kibana 4.1 + ES 1.5"
    exit 0
    ;;
  4.4 )
    ES_VERSION=2.2
    ;;
  * )
    ES_VERSION="$TAG"
    ;;
esac

DB_CONTAINER="kbelastic"
DATA_CONTAINER="${DB_CONTAINER}-data"
ES_IMG="quay.io/aptible/elasticsearch:${ES_VERSION}"
KIBANA_CONTAINER="kibana-${TAG}"
KIBANA_CREDS=kuser:kpass
ES_USER=euser 
ES_PASS=epass

function cleanup {
  echo "Cleaning up"
  docker rm -f "$DB_CONTAINER" "$DATA_CONTAINER" "$KIBANA_CONTAINER" > /dev/null 2>&1 || true
}

function wait_for_request {
  CONTAINER=$1
  shift

  for _ in $(seq 1 30); do
    if docker exec -it "$CONTAINER" curl -f -v "$@" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "No response"
  docker logs "$CONTAINER"
  return 1
}

trap cleanup EXIT
cleanup

echo "Creating data container"
docker create --name "$DATA_CONTAINER" "${ES_IMG}"

echo "Starting DB"
docker run -it --rm \
  -e USERNAME=${ES_USER} -e PASSPHRASE=${ES_PASS} -e DATABASE=db \
  --volumes-from "$DATA_CONTAINER" \
  "${ES_IMG}" --initialize \
  >/dev/null 2>&1

docker run -d --name="$DB_CONTAINER" \
  --volumes-from "$DATA_CONTAINER" \
  "${ES_IMG}"

echo "Waiting for DB to come online"
wait_for_request "$DB_CONTAINER" "http://localhost:9200"

ES_IP="$(docker inspect --format='{{.NetworkSettings.Networks.bridge.IPAddress}}' ${DB_CONTAINER})"

echo "Starting Kibana"
docker run -d --name="$KIBANA_CONTAINER" \
  -e DATABASE_URL="http://${ES_USER}:${ES_PASS}@${ES_IP}:80" \
  -e AUTH_CREDENTIALS="$KIBANA_CREDS" \
  -e TESTING="true" \
  "$IMG"

wait_for_request "${KIBANA_CONTAINER}" \
  'http://localhost:5601/elasticsearch/*/_search' \
  -H "kbn-version: $KIBANA_VERSION" \
  -H 'content-type: application/json' \
  --data-binary '{}'

wait_for_request "${KIBANA_CONTAINER}" \
  'http://localhost:5601/app/kibana' \
  -H "kbn-version: $KIBANA_VERSION"
