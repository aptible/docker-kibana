FROM quay.io/aptible/ubuntu:14.04

# Install NGiNX.
RUN apt-get update && \
    apt-get install -y software-properties-common \
    python-software-properties && \
    add-apt-repository -y ppa:nginx/stable && apt-get update && \
    apt-get -y install curl ucspi-tcp apache2-utils nginx ruby

# Download Kibana 4.0.2, extract into /opt/kibana-4.0.2.
RUN curl -O https://download.elastic.co/kibana/kibana/kibana-4.0.2-linux-x64.tar.gz && \
    echo "c925f75cd5799bfd892c7ea9c5936be10a20b119  kibana-4.0.2-linux-x64.tar.gz" | sha1sum -c - && \
    tar zxf kibana-4.0.2-linux-x64.tar.gz -C /opt

# Overwrite default nginx config with our config.
RUN rm /etc/nginx/sites-enabled/*
ADD templates/sites-enabled /
RUN rm /opt/kibana-4.0.2-linux-x64/config/kibana.yml
ADD templates/opt/kibana-4.0.2/ /

# Add script that starts NGiNX in front of Kibana and tails the NGiNX access/error logs.
ADD bin .
RUN chmod 700 ./run-kibana.sh

# Run tests.
ADD test /tmp/test
RUN bats /tmp/test

EXPOSE 80

CMD ["./run-kibana.sh"]