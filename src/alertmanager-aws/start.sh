#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

config_file=\
"${ALERTMANAGER_CONFIG_FILE:-/opt/alertmanager/conf/alertmanager.yml}"
storage_path=\
"${ALERTMANAGER_STORAGE_PATH:-/var/opt/alertmanager}"

web_listen_address=\
"${ALERTMANAGER_WEB_LISTEN_ADDRESS:-:9093}"

cluster_listen_address=\
"${ALERTMANAGER_CLUSTER_LISTEN_ADDRESS:-0.0.0.0:9094}"

cluster_advertise_address_option=
if [ -n "${ALERTMANAGER_CLUSTER_ADVERTISE_ADDRESS}" ]; then
  address="${ALERTMANAGER_CLUSTER_ADVERTISE_ADDRESS}"
  cluster_advertise_address_option="--cluster.advertise-address=${address}"
fi

cluster_peer_options=()
for cluster_peer in ${ALERTMANAGER_CLUSTER_PEERS//,/ }; do
  cluster_peer_options+=("--cluster.peer=${cluster_peer}")
done

log_level="${ALERTMANAGER_LOG_LEVEL:-info}"
log_format="${ALERTMANAGER_LOG_FORMAT:-json}"

echo "Running alertmanager."
# shellcheck disable=SC2086
exec su-exec alertmgr:alertmgr /opt/alertmanager/bin/alertmanager \
    --config.file="${config_file}" \
    \
    --storage.path="${storage_path}" \
    \
    --web.listen-address="${web_listen_address}" \
    \
    --cluster.listen-address="${cluster_listen_address}" \
    ${cluster_advertise_address_option} \
    "${cluster_peer_options[@]}" \
    \
    --log.level="${log_level}" \
    --log.format="${log_format}"
