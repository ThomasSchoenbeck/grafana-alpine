FROM alpine:latest

# Define Environment variables
ENV GRAFANA_VERSION=${GRAFANA_VERSION} \
    CADVISOR_VERSION=${CADVISOR_VERSION} \
    GLIBC_VERSION=${GLIBC_VERSION} \
    MKDIR_PATHS="/opt/grafana /opt/grafana/home /var/log/grafana /var/lib/grafana/data /var/lib/grafana/plugins /opt/grafana/provisioning /tmp/grafana/plugins" \
    PERMISSON_PATHS="/run /tmp /usr/local/bin /var/log /var/lib /var/tmp"

RUN apk update; \
    apk upgrade --update; \
    apk add --update --no-cache \
        curl \
        tini; \
    rm -rf /var/cache/apk/*; \
    rm -rf /tmp/*;

# alpine glibc fix https://github.com/sgerrand/alpine-pkg-glibc/releases
RUN curl -L https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk -o /tmp/glibc-${GLIBC_VERSION}.apk; \
    ls -la /tmp; \
    apk add --allow-untrusted /tmp/glibc-${GLIBC_VERSION}.apk; \
    rm -rf /tmp/*; \
    ls -la /tmp;

# download and install cadvisor
RUN set -xe; \
    # download cadvisor
    curl -L https://github.com/google/cadvisor/releases/download/v${CADVISOR_VERSION}/cadvisor \
         -o /usr/local/bin/cadvisor;

RUN set -xe; \
    # create needed paths
    mkdir -p ${MKDIR_PATHS}; \
    # download grafana
    curl https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz -o /tmp/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz; \
    # unpack and move grafana
    tar -xzf /tmp/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz -C /tmp ; \
    ls -la /tmp; \
    mv /tmp/grafana-${GRAFANA_VERSION}/* /opt/grafana/; \
    # clear temp
    rm -rf /tmp/grafana-${GRAFANA_VERSION}; \
    ls -la /tmp;

COPY files-to-copy/root/ /

# download plugins
RUN set -xe; \ 
    cd /tmp/grafana/plugins/; \
    curl -L https://grafana.com/api/plugins/ryantxu-ajax-panel/versions/0.0.7-dev/download -o /tmp/grafana/plugins/ryantxu-ajax-panel-d3605f9.zip; \
    curl -L https://grafana.com/api/plugins/grafana-worldmap-panel/versions/0.2.1/download -o /tmp/grafana/plugins/grafana-worldmap-panel-95f8956.zip; \
    curl -L https://grafana.com/api/plugins/grafana-piechart-panel/versions/1.3.9/download -o /tmp/grafana/plugins/grafana-piechart-panel-v1.3.9-0-gec46c48.zip; \
    curl -L https://grafana.com/api/plugins/grafana-clock-panel/versions/1.0.3/download -o /tmp/grafana/plugins/grafana-clock-panel-v1.0.3-0-gbb466d0.zip; \
    curl -L https://grafana.com/api/plugins/snuids-radar-panel/versions/1.4.4/download -o /tmp/grafana/plugins/snuids-grafana-radar-panel-34713c1.zip; \
    ls -la /tmp/grafana/plugins;

# setup paths and permissions
RUN set -xe \
    chgrp -R nobody ${PERMISSON_PATHS}; \
    chmod -R 777 ${PERMISSON_PATHS}; \
    ls -la ${PERMISSON_PATHS};

# let tini handle all the zombie processes
ENTRYPOINT ["/sbin/tini", "--"]

# start all required processes
CMD ["/usr/local/bin/start_processes.sh"]