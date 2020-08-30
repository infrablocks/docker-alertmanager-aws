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

cluster_peer_timeout="${ALERTMANAGER_CLUSTER_PEER_TIMEOUT:-15s}"
cluster_gossip_interval="${ALERTMANAGER_CLUSTER_GOSSIP_INTERVAL:-200ms}"
cluster_pushpull_interval="${ALERTMANAGER_CLUSTER_PUSHPULL_INTERVAL:-1m0s}"
cluster_tcp_timeout="${ALERTMANAGER_CLUSTER_TCP_TIMEOUT:-10s}"
cluster_probe_timeout="${ALERTMANAGER_CLUSTER_PROBE_TIMEOUT:-500ms}"
cluster_probe_interval="${ALERTMANAGER_CLUSTER_PROBE_INTERVAL:-1s}"
cluster_settle_timeout="${ALERTMANAGER_CLUSTER_SETTLE_TIMEOUT:-1m0s}"
cluster_reconnect_interval="${ALERTMANAGER_CLUSTER_RECONNECT_INTERVAL:-10s}"
cluster_reconnect_timeout="${ALERTMANAGER_CLUSTER_RECONNECT_TIMEOUT:-6h0m0s}"

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
    --cluster.peer-timeout="${cluster_peer_timeout}" \
    --cluster.gossip-interval="${cluster_gossip_interval}" \
    --cluster.pushpull-interval="${cluster_pushpull_interval}" \
    --cluster.tcp-timeout="${cluster_tcp_timeout}" \
    --cluster.probe-timeout="${cluster_probe_timeout}" \
    --cluster.probe-interval="${cluster_probe_interval}" \
    --cluster.settle-timeout="${cluster_settle_timeout}" \
    --cluster.reconnect-interval="${cluster_reconnect_interval}" \
    --cluster.reconnect-timeout="${cluster_reconnect_timeout}" \
    ${cluster_advertise_address_option} \
    "${cluster_peer_options[@]}" \
    \
    --log.level="${log_level}" \
    --log.format="${log_format}"
