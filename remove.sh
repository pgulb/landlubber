#!/usr/bin/env bash

./pretty_log.sh "Running remove.sh"

source ./default.env &&
source ./.env ;

./init_hcloud.sh $PUBKEY $HCLOUD_TOKEN 0 &&
./hcloud server delete $NODE1
./hcloud server delete $NODE2
./hcloud server delete $NODE3
