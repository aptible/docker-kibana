#!/bin/bash
set -o errexit
set -o nounset

IMG="$REGISTRY/$REPOSITORY:$TAG"

echo "Installing Busybox and running bats tests"
docker run -i --rm --entrypoint "bash" "$IMG" -c "apt-install -y busybox > /dev/null 2>&1 && bats /tmp/test"

./test-auth.sh "$IMG" "$TAG"

echo "Test OK!"
