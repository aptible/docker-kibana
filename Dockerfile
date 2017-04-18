FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update && \
    apt-get install -y software-properties-common \
    python-software-properties \
    python-pip && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils nginx ruby && \
    pip install elasticsearch-curator

# We're going to install 2 versions of Kibana, and choose which one to start
# at runtime based on the Elasticsearch version we see:
# - Kibana 4.1.X supports Elasticsearch 1.x
# - Kibana 4.4.X supports Elasticsearch 2.2

ENV KIBANA_41_VERSION 4.1.11
ENV KIBANA_41_SHA1SUM 13655cf94f5c47e8ab4d94c8170128f63be46ad5

ENV KIBANA_44_VERSION 4.4.2
ENV KIBANA_44_SHA1SUM 6251dbab12722ea1a036d8113963183f077f9fa7

ENV KIBANA_5_VERSION 5.0.1
ENV KIBANA_5_SHA1SUM 66f058017219d23ef5534545f5c6ad1dca4bb1fd

# Kibana 4.1
RUN curl -fsSLO "https://download.elastic.co/kibana/kibana/kibana-${KIBANA_41_VERSION}-linux-x64.tar.gz" && \
    echo "${KIBANA_41_SHA1SUM}  kibana-${KIBANA_41_VERSION}-linux-x64.tar.gz" | sha1sum -c - && \
    tar xzf "kibana-${KIBANA_41_VERSION}-linux-x64.tar.gz" -C /opt && \
    mv "/opt/kibana-${KIBANA_41_VERSION}-linux-x64" "/opt/kibana-${KIBANA_41_VERSION}" && \
    rm "kibana-${KIBANA_41_VERSION}-linux-x64.tar.gz"

# Kibana 4.4
RUN curl -fsSLO "https://download.elastic.co/kibana/kibana/kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz" && \
    echo "${KIBANA_44_SHA1SUM}  kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz" | sha1sum -c - && \
    tar xzf "kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz" -C /opt && \
    mv "/opt/kibana-${KIBANA_44_VERSION}-linux-x64" "/opt/kibana-${KIBANA_44_VERSION}" && \
    rm "kibana-${KIBANA_44_VERSION}-linux-x64.tar.gz"

# Kibana 5
RUN curl -fsSLO "https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_5_VERSION}-linux-x86_64.tar.gz" && \
    echo "${KIBANA_5_SHA1SUM}  kibana-${KIBANA_5_VERSION}-linux-x86_64.tar.gz" | sha1sum -c - && \
    tar xzf "kibana-${KIBANA_5_VERSION}-linux-x86_64.tar.gz" -C /opt && \
    mv "/opt/kibana-${KIBANA_5_VERSION}-linux-x86_64" "/opt/kibana-${KIBANA_5_VERSION}" && \
    rm "kibana-${KIBANA_5_VERSION}-linux-x86_64.tar.gz"

# Overwrite default nginx config with our config.
RUN rm /etc/nginx/sites-enabled/*
ADD templates/sites-enabled /

RUN rm "/opt/kibana-${KIBANA_41_VERSION}/config/kibana.yml" \
 && rm "/opt/kibana-${KIBANA_44_VERSION}/config/kibana.yml" \
 && rm "/opt/kibana-${KIBANA_5_VERSION}/config/kibana.yml"
ADD templates/opt/kibana-4.1.x/ /opt/kibana-${KIBANA_41_VERSION}/config
ADD templates/opt/kibana-4.4.x/ /opt/kibana-${KIBANA_44_VERSION}/config
ADD templates/opt/kibana-5.x/ /opt/kibana-${KIBANA_5_VERSION}/config

ADD patches /patches
RUN patch -p1 -d "/opt/kibana-${KIBANA_44_VERSION}" < /patches/0001-Set-authorization-header-when-connecting-to-ES.patch

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibana.sh
RUN chmod 700 ./start-cron.sh

# Add tests. Those won't run as part of the build because customers don't need to run
# them when deploying, but they'll be run in test.sh
ADD test /tmp/test

EXPOSE 80

ADD . /app
RUN set -a && . /app/.aptible.env
RUN ./start-cron.sh

CMD ["./run-kibana.sh"]
