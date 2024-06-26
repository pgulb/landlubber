#!/usr/bin/env bash

curl -sfL https://get.k3s.io | sh -s - server \
    --cluster-cidr=10.42.0.0/16,2001:cafe:42:0::/56 \
    --service-cidr=10.43.0.0/16,2001:cafe:42:1::/112 \
    --disable=local-storage \
    --etcd-disable-snapshots \
    --cluster-init &&

cat /var/lib/rancher/k3s/server/token | awk -F':' '{print $NF}' > /root/k3s_token
