FROM alpine:3.6

# Install NGiNX.
RUN apk update && \
    apk upgrade && \
    apk add --update curl openssl bash ruby nodejs && \
    rm -rf /var/cache/apk/*

# We're going to install 2 versions of Kibana, and choose which one to start
# at runtime based on the Elasticsearch version we see:
# - Kibana 4.1.X supports Elasticsearch 1.x
# - Kibana 4.4.X supports Elasticsearch 2.x

ENV KIBANA_41_VERSION 4.1.11
ENV KIBANA_41_SHA1SUM 13655cf94f5c47e8ab4d94c8170128f63be46ad5
ENV PKG_NAME kibana
ENV PKG_PLATFORM linux-x64
ENV KIBANA_41_PKG $PKG_NAME-$KIBANA_41_VERSION-$PKG_PLATFORM

# Kibana 4.1
RUN echo "Downloading https://download.elastic.co/kibana/kibana/${KIBANA_41_PKG}.tar.gz" && \
    echo "node found at $(which node)" && \
    curl -O "https://download.elastic.co/kibana/kibana/${KIBANA_41_PKG}.tar.gz" && \
    mkdir /opt && \
    echo "${KIBANA_41_SHA1SUM}  ${KIBANA_41_PKG}.tar.gz" | sha1sum -c - && \
    tar xzf "${KIBANA_41_PKG}.tar.gz" -C /opt && \
    rm "${KIBANA_41_PKG}.tar.gz" && \
    rm -fr /opt/${KIBANA_41_PKG}/node/ && \
    mkdir -p /opt/${KIBANA_41_PKG}/node/bin/  && \
    ln -s $(which node) /opt/${KIBANA_41_PKG}/node/bin/node

# Download Oauth2 Proxy 2.0.1, extract into /opt/oauth2_proxy
RUN curl -L -O https://github.com/bitly/oauth2_proxy/releases/download/v2.2/oauth2_proxy-2.2.0.linux-amd64.go1.8.1.tar.gz && \
  echo "1c73bc38141e079441875e5ea5e1a1d6054b4f3b  oauth2_proxy-2.2.0.linux-amd64.go1.8.1.tar.gz" | sha1sum -c - && \
  tar zxf oauth2_proxy-2.2.0.linux-amd64.go1.8.1.tar.gz -C /opt && \
  mv /opt/oauth2_proxy-2.2.0.linux-amd64.go1.8.1 /opt/oauth2_proxy

# Overwrite default config with our config.
RUN rm "/opt/${KIBANA_41_PKG}/config/kibana.yml"
ADD templates/opt/kibana-4.1.x/ /opt/kibana-${KIBANA_41_VERSION}/config

ADD patches /patches

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibana.sh

# Add tests. Those won't run as part of the build because customers don't need to run
# them when deploying, but they'll be run in test.sh
ADD test /tmp/test

EXPOSE 80

CMD ["./run-kibana.sh"]