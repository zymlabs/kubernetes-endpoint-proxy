# Kubernetes Endpoint Proxy

An HAProxy for load balancing Kubernetes endpoints.
Particularly useful for running Kubernetes on Mesos/Mesosphere DCOS. This is because
in a Kubernetes cluster the endpoint ports and IP addresses may change for a service.

This proxy will monitor the endpoint for changes in etcd and update HAProxy with the new
endpoints.

## Getting Started

Given the following service in Kubernetes, we will run the proxy container with
the options below.

### Environment Variables

 - ETCD_SCHEME - etcd connection scheme (http)
 - ETCD_HOST - etcd host (leader.mesos)
 - ETCD_PORT - etcd port (4001)
 - KUBERNETES_ENDPOINT - Kubernetes endpoint id or service id
 - HAPROXY_HEALTH_CHECK_PATH - Optional path for checking if an endpoint upstream is available.

### Kubernetes Service pandora-nginx
    {
        "id": "pandora-nginx",
        "kind": "Service",
        "apiVersion": "v1beta1",
        "port": 80,
        "containerPort": 80,
        "selector": {
            "name": "pandora-nginx"
        },
        "labels": { "name": "pandora-nginx" }
    }

### Docker Example
    docker run -e "ETCD_HOST=leader.mesos" \
               -e "ETCD_PORT=4001" \
               -e "KUBERNETES_ENDPOINT=pandora-nginx" \
               -e "HAPROXY_HEALTH_CHECK_PATH=/robots.txt" \
               -p 80:80 \
               zymlabs/kubernetes-endpoint-proxy

Requests should then be routed through the proxy to the endpoint.
