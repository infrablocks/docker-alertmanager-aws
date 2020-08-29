FROM infrablocks/alpine-aws-s3-config:0.20.0

ENV ALERTMANAGER_VERSION 0.21.0

RUN cd /tmp \
    && curl \
        -L "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz" \
        -o "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz" \
    && tar -xvf "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz" \
    && mkdir -p /opt/alertmanager \
    && cp -R "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64"/* /opt/alertmanager \
    && mkdir -p /opt/alertmanager/bin \
    && rm "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz" \
    && rm -rf "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64" \
    && cd /

COPY start.sh /opt/alertmanager/bin/start.sh
COPY scripts/fetch-configuration.sh /opt/alertmanager/scripts/fetch-configuration.sh

RUN chmod +x /opt/alertmanager/bin/start.sh
RUN chmod +x /opt/alertmanager/scripts/fetch-configuration.sh

ENV STARTUP_SCRIPT_PATH=/opt/alertmanager/bin/start.sh
ENV FETCH_SECRETS_FILES_SCRIPT_PATH=/opt/alertmanager/scripts/fetch-configuration.sh
