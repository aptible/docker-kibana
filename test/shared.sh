cleanup() {
  service nginx stop
  rm /etc/nginx/conf.d/kibana.htpasswd || true
  rm /etc/nginx/sites-enabled/kibana || true
  rm /var/log/nginx/access.log || true
  rm /var/log/nginx/error.log || true
  pkill nc || true
  pkill busybox || true
  rm -f "/opt/kibana/config/kibana.yml"
}