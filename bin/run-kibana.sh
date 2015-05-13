#!/bin/bash
: ${AUTH_CREDENTIALS:?"Error: environment variable AUTH_CREDENTIALS should be populated with a comma-separated list of user:password pairs. Example: \"admin:pa55w0rD\"."}
: ${DATABASE_URL:?"Error: environment variable DATABASE_URL should be set to the Aptible DATABASE_URL of the Elasticsearch instance you wish to use."}

# Parse auth credentials, add to a htpasswd file.
AUTH_PARSER="
create_opt = 'c'
ENV['AUTH_CREDENTIALS'].split(',').map do |creds|
  user, password = creds.split(':')
  %x(htpasswd -b#{create_opt} /etc/nginx/conf.d/kibana.htpasswd #{user} #{password})
  create_opt = ''
end"
ruby -e "$AUTH_PARSER" || \
(echo "Error creating htpasswd file from credentials '$AUTH_CREDENTIALS'" && exit 1)

erb -T 2 -r uri -r base64 ./kibana.erb > /etc/nginx/sites-enabled/kibana || \
(echo "Error creating nginx configuration from Elasticsearch url '$DATABASE_URL'" && exit 1)

# Run config
erb -T 2 -r uri ./config.yml.erb > /opt/kibana-4.1.0-snapshot-linux-x64/config/kibana.yml || \
(echo "Error creating kibana config file" && exit 1);

service nginx start
/opt/kibana-4.1.0-snapshot-linux-x64/bin/kibana