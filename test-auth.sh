#!/bin/bash
set -o errexit
set -o nounset

IMG="$1"
TAG="$2"

DB_CONTAINER="kbelastic"
DATA_CONTAINER="${DB_CONTAINER}-data"
ES_IMG="quay.io/aptible/elasticsearch-security:${TAG}"
KIBANA_CONTAINER="kibana-${TAG}"
ES_USER=euser
ES_PASS=epassword

function cleanup {
  echo "Cleaning up"
  docker rm -f "$DB_CONTAINER" "$DATA_CONTAINER" "$KIBANA_CONTAINER" > /dev/null 2>&1 || true
}

function wait_for_request {
  CONTAINER=$1
  shift

  for _ in $(seq 1 30); do
    if docker exec -it "$CONTAINER" curl -k -f -v "$@" >/dev/null 2>&1; then
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
wait_for_request "$DB_CONTAINER" "https://${ES_USER}:${ES_PASS}@localhost:9200"

ES_IP="$(docker inspect --format='{{.NetworkSettings.Networks.bridge.IPAddress}}' ${DB_CONTAINER})"

echo "Starting Kibana"
docker run -d --name="$KIBANA_CONTAINER" \
  -e DATABASE_URL="https://${ES_USER}:${ES_PASS}@${ES_IP}:9200" \
  "$IMG"

echo "Wait for kibana to boot"
wait_for_request "${KIBANA_CONTAINER}" \
  'http://localhost:80/' >/dev/null 2>&1

echo "Make sure it returns an error without auth."
# Should return exit status 22 representing a >400 response, in this case a 401
docker exec "${KIBANA_CONTAINER}" curl -fs \
  'http://localhost:80/api/index_management/indices' \
  -H 'Accept: application/json' -H 'kbn-version: 7.4.2' \
  || [[ $? == 22 ]]

echo "Make sure the elasticsearch user/pass can authenticate."
docker exec "${KIBANA_CONTAINER}" curl -fs \
  -u euser:epassword \
  'http://localhost:80/api/index_management/indices' \
  -H 'Accept: application/json' -H 'kbn-version: 7.4.2' >/dev/null 2>&1
