FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update && \
    apt-get install -y software-properties-common \
    python-software-properties && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils ruby

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
    tar xzf "kibana-${KIBANA_41_VERSION}-linux-x64.tar.gz" -C /opt && \
    rm "kibana-${KIBANA_41_VERSION}-linux-x64.tar.gz"

# Kibana 4.4
RUN curl -O "https://download.elastic.co/kibana/kibana/kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz" && \
    echo "${KIBANA_44_SHA1SUM}  kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz" | sha1sum -c - && \
    tar xzf "kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz" -C /opt && \
    rm "kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz"

# Download Oauth2 Proxy 2.0.1, extract into /opt/oauth2_proxy
RUN curl -L -O https://github.com/bitly/oauth2_proxy/releases/download/v2.0.1/oauth2_proxy-2.0.1.linux-amd64.go1.4.2.tar.gz && \
  echo "950e08d52c04104f0539e6945fc42052b30c8d1b  oauth2_proxy-2.0.1.linux-amd64.go1.4.2.tar.gz" | sha1sum -c - && \
  tar zxf oauth2_proxy-2.0.1.linux-amd64.go1.4.2.tar.gz -C /opt && \
  mv /opt/oauth2_proxy-2.0.1.linux-amd64.go1.4.2 /opt/oauth2_proxy

# Overwrite default config with our config.
RUN rm "/opt/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml" \
 && rm "/opt/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
ADD templates/opt/kibana-4.1.x/ /opt/kibana-${KIBANA_41_VERSION}/config
ADD templates/opt/kibana-4.4.x/ /opt/kibana-${KIBANA_44_VERSION}/config

ADD patches /patches
RUN patch -p1 -d /opt/kibana-4.4.1-linux-x64 < /patches/0001-Set-authorization-header-when-connecting-to-ES.patch

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibana.sh

# Add tests. Those won't run as part of the build because customers don't need to run
# them when deploying, but they'll be run in test.sh
ADD test /tmp/test

EXPOSE 80

CMD ["./run-kibana.sh"]
