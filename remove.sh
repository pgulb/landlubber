#!/usr/bin/env bash

./pretty_log.sh "Running remove.sh"

source ./default.env &&
source ./.env ;

./pretty_log.sh "Removing output files"
rm -rf ./output/*.log*
rm -rf ./output/*_token*
rm -rf ./output/*_pass*
rm -rf ./output/kubeadm_join.sh
rm -rf ./output/.kubeconfig
rm -rf ./output/public_ipv4*

./pretty_log.sh "Removing VMs"
./init_hcloud.sh $PUBKEY $HCLOUD_TOKEN 0 &&
./hcloud server delete $NODE1
./hcloud server delete $NODE2
./hcloud server delete $NODE3
./hcloud network delete landlubber
