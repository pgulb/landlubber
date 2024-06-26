#!/usr/bin/env bash

curl -sfL https://get.k3s.io | sh -s - server \
    --server=https://NODE1:6443 \
    --token=JOIN_TOKEN \
    --cluster-cidr=10.42.0.0/16,2001:cafe:42:0::/56 \
    --service-cidr=10.43.0.0/16,2001:cafe:42:1::/112 \
    --disable=local-storage \
    --etcd-disable-snapshots
