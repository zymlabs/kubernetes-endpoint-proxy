#!/bin/bash

set -eo pipefail

# Default environment variables
: ${ETCD_SCHEME:="http"}
: ${ETCD_HOST:="leader.mesos"}
: ${ETCD_PORT:="4001"}

export ETCD_PROTOCOL
export ETCD_HOST
export ETCD_PORT

# Generate configuration by looping through .dist files in /etc/nginx/conf.d/default.conf
for f in /etc/haproxy/errors/*.html
do
    # Replace ${VAR} with variables set in environment.
    perl -p -e 's/\$\{([^}]+)\}/defined $ENV{$1} ? $ENV{$1} : $&/eg' $f > $f
done

if [ -z "$KUBERNETES_ENDPOINT" ]; then
    echo "Environment variable KUBERNETES_ENDPOINT must be set with the Kubernetes service id"
    exit 1
fi

echo "[kubernetes-endpoint-proxy] Starting Mesos Kubernetes Proxy..."

# Loop until confd has updated the haproxy config
until confd -onetime -node $ETCD_SCHEME://$ETCD_HOST:$ETCD_PORT -config-file /etc/confd/conf.d/haproxy.toml; do
  echo "[kubernetes-endpoint-proxy] Waiting for confd to refresh haproxy.cfg"
  sleep 5
done

# Run confd in the background to watch the upstream servers
confd -interval 10 -node $ETCD_SCHEME://$ETCD_HOST:$ETCD_PORT -config-file /etc/confd/conf.d/haproxy.toml &
echo "[kubernetes-endpoint-proxy] confd is listening for changes on etcd..."

echo "[kubernetes-endpoint-proxy] Starting HAProxy..."
exec /usr/bin/supervisord
