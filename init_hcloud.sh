#!/usr/bin/env bash

# $1 = Public key
# $2 = HCLOUD_TOKEN
# $3 = 0/1 - keep/remove ssh key from hcloud

./pretty_log.sh "Running init_hcloud.sh"

mkdir -p $HOME/.config/hcloud &&
mv ./cli.toml $HOME/.config/hcloud/ &&
sed -i s/changeme/$2/ $HOME/.config/hcloud/cli.toml &&
if [ $3 -eq 0 ]; then
    ./pretty_log.sh "Keeping existing ssh key in hcloud"
else
    ./hcloud ssh-key delete landlubber-key
    ./hcloud ssh-key create --name landlubber-key --public-key-from-file $1
    ./pretty_log.sh "Creating hcloud network"
    ./hcloud network create --name=landlubber --ip-range 10.10.0.0/16
    ./hcloud network add-subnet landlubber \
    --network-zone=eu-central --type=server --ip-range 10.10.0.0/16
fi
