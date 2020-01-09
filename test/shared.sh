cleanup() {
  pkill nc || true
  pkill busybox || true
  rm -f "/opt/kibana/config/kibana.yml"
}