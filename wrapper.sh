#!/usr/bin/env bash

./pretty_log.sh "Running wrapper.sh"
source ./default.env &&
source ./.env ;
./generate_ed25519.sh &&
./init_hcloud.sh $PUBKEY $HCLOUD_TOKEN 1 &&

sed -i s/KUBE_VER/$KUBE_VER/g ./setup_kubeadm.sh &&
sed -i s/CRI_DOCKERD_VER/$CRI_DOCKERD_VER/g ./setup_kubeadm.sh &&

./create.sh 1 $PRIVKEY $NODE1 &&
./create.sh 2 $PRIVKEY $NODE2 &&
./create.sh 3 $PRIVKEY $NODE3 &&

chown -R $HOST_UID:$HOST_GID ./output/*
chown -R $HOST_UID:$HOST_GID ./output/.*
