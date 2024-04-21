#!/usr/bin/env bash

./pretty_log.sh "Running wrapper.sh"
source ./default.env &&
source ./.env ;
./generate_ed25519.sh &&
./init_hcloud.sh $PUBKEY $HCLOUD_TOKEN 1 &&
./create.sh 1 $PRIVKEY $NODE1 &&
exit 1
./create.sh 2 $PRIVKEY $NODE2 &&
./create.sh 3 $PRIVKEY $NODE3 &&
