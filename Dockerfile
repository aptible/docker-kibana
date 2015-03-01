FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update
RUN apt-get install -y software-properties-common \
    python-software-properties && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils nginx ruby

# Download Kibana 3.1.2, extract into /opt/kibana-3.1.2.
RUN curl -O https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz && \
    echo "a59ea4abb018a7ed22b3bc1c3bcc6944b7009dc4  kibana-3.1.2.tar.gz" | sha1sum -c - && \
    tar zxf kibana-3.1.2.tar.gz -C /opt

# Overwrite default nginx config with our config.
RUN rm /etc/nginx/sites-enabled/*
ADD templates/sites-enabled /
RUN rm /opt/kibana-3.1.2/config.js
ADD templates/opt/kibana-3.1.2 /

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibana.sh

# Run tests.
ADD test /tmp/test
RUN bats /tmp/test

EXPOSE 80

CMD ["./run-kibana.sh"]