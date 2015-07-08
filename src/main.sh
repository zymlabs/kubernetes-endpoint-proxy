#!/bin/bash

set -eo pipefail

# Default environment variables
: ${ETCD_PROTOCOL:="http"}
: ${ETCD_HOST:="leader.mesos"}
: ${ETCD_PORT:="4001"}

export ETCD_PROTOCOL
export ETCD_HOST
export ETCD_PORT

if [ -z "$KUBERNETES_ENDPOINT" ]; then
    echo "Environment variable KUBERNETES_ENDPOINT must be set with the Kubernetes service id"
    exit 1
fi

echo "[mesos-kubernetes-proxy] Starting Mesos Kubernetes Proxy..."

# Loop until confd has updated the haproxy config
until confd -onetime -node $ETCD_PROTOCOL://$ETCD_HOST:$ETCD_PORT -config-file /etc/confd/conf.d/haproxy.toml; do
  echo "[mesos-kubernetes-proxy] Waiting for confd to refresh haproxy.cfg"
  sleep 5
done

# Run confd in the background to watch the upstream servers
confd -interval 10 -node $ETCD_PROTOCOL://$ETCD_HOST:$ETCD_PORT -config-file /etc/confd/conf.d/haproxy.toml &
echo "[mesos-kubernetes-proxy] confd is listening for changes on etcd..."

echo "[mesos-kubernetes-proxy] Starting HAProxy..."
exec haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid
