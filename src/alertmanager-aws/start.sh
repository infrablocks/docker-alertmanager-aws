#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

ALERTMANAGER_CONFIG_FILE=\
"${ALERTMANAGER_CONFIG_FILE:-/opt/alertmanager/conf/alertmanager.yml}"
ALERTMANAGER_STORAGE_PATH=\
"${ALERTMANAGER_STORAGE_PATH:-/var/opt/alertmanager}"

ALERTMANAGER_LOG_LEVEL="${ALERTMANAGER_LOG_LEVEL:-info}"
ALERTMANAGER_LOG_FORMAT="${ALERTMANAGER_LOG_FORMAT:-json}"

echo "Running alertmanager."
exec su-exec alertmgr:alertmgr /opt/alertmanager/bin/alertmanager \
    --config.file="${ALERTMANAGER_CONFIG_FILE}" \
    \
    --storage.path="${ALERTMANAGER_STORAGE_PATH}" \
    \
    --log.level="${ALERTMANAGER_LOG_LEVEL}" \
    --log.format="${ALERTMANAGER_LOG_FORMAT}"
