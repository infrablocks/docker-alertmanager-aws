FROM infrablocks/alpine-aws-s3-config:0.22.0

ENV ALERTMANAGER_VERSION 0.21.0

RUN apk \
    --verbose \
    --no-cache \
    add \
        su-exec

RUN addgroup -S alertmgr && \
    adduser -S -G alertmgr alertmgr

RUN cd /tmp \
    && curl \
        -L "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz" \
        -o "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz" \
    && tar -xvf "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz" \
    && mkdir -p /opt/alertmanager \
    && cp -R "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64"/* /opt/alertmanager \
    && mkdir -p /opt/alertmanager/bin \
    && mkdir -p /opt/alertmanager/conf \
    && mv /opt/alertmanager/alertmanager /opt/alertmanager/bin/alertmanager \
    && mv /opt/alertmanager/amtool /opt/alertmanager/bin/amtool \
    && mv /opt/alertmanager/alertmanager.yml /opt/alertmanager/conf/alertmanager.yml \
    && rm "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz" \
    && rm -rf "alertmanager-${ALERTMANAGER_VERSION}.linux-amd64" \
    && cd /

COPY start.sh /opt/alertmanager/bin/start.sh
COPY scripts/fetch-configuration.sh /opt/alertmanager/scripts/fetch-configuration.sh

RUN chmod +x /opt/alertmanager/bin/start.sh
RUN chmod +x /opt/alertmanager/scripts/fetch-configuration.sh

RUN mkdir -p /var/opt/alertmanager \
    && chown -R alertmgr:alertmgr \
        /opt/alertmanager \
        /var/opt/alertmanager

EXPOSE 9093 9094

ENV STARTUP_SCRIPT_PATH=/opt/alertmanager/bin/start.sh
ENV FETCH_SECRETS_FILES_SCRIPT_PATH=/opt/alertmanager/scripts/fetch-configuration.sh
