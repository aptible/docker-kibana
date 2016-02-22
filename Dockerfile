FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update && \
    apt-get install -y software-properties-common \
    python-software-properties && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils nginx ruby

# We're going to install 2 versions of Kibana, and choose which one to start
# at runtime based on the Elasticsearch version we see:
# - Kibana 4.1.X supports Elasticsearch 1.x
# - Kibana 4.4.X supports Elasticsearch 2.x

ENV KIBANA_41_VERSION 4.1.5
ENV KIBANA_41_SHA1SUM 7c1e597f69abd2c9c2b4de045350199d8b187a9a

ENV KIBANA_44_VERSION 4.4.1
ENV KIBANA_44_SHA1SUM b4f1b5d89a0854e3fb1e6d31faa1bc78e063b083

# Kibana 4.1
RUN curl -O "https://download.elastic.co/kibana/kibana/kibana-${KIBANA_41_VERSION}-linux-x64.tar.gz" && \
    echo "${KIBANA_41_SHA1SUM}  kibana-${KIBANA_41_VERSION}-linux-x64.tar.gz" | sha1sum -c - && \
    tar xzf "kibana-${KIBANA_41_VERSION}-linux-x64.tar.gz" -C /opt

# Kibana 4.4
RUN curl -O "https://download.elastic.co/kibana/kibana/kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz" && \
    echo "${KIBANA_44_SHA1SUM}  kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz" | sha1sum -c - && \
    tar xzf "kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz" -C /opt

# Overwrite default nginx config with our config.
RUN rm /etc/nginx/sites-enabled/*
ADD templates/sites-enabled /

RUN rm "/opt/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml" \
 && rm "/opt/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
ADD templates/opt/kibana-4.1.x/ /opt/kibana-${KIBANA_41_VERSION}/config
ADD templates/opt/kibana-4.4.x/ /opt/kibana-${KIBANA_44_VERSION}/config

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibana.sh

# Run tests.
ADD test /tmp/test
RUN bats /tmp/test

EXPOSE 80

CMD ["./run-kibana.sh"]
