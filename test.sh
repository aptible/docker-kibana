#!/bin/bash
set -o errexit
set -o nounset

IMG="$REGISTRY/$REPOSITORY:$TAG"

echo "Running bats tests"
docker run -i --entrypoint "bats" "$IMG" "/tmp/test"

echo "Test OK!"
