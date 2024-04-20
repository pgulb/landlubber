#!/usr/bin/env bash

mkdir -p $HOME/.config/hcloud &&
mv ./cli.toml $HOME/.config/hcloud/ &&
sed -i s/changeme/$2/ $HOME/.config/hcloud/cli.toml &&
./hcloud ssh-key delete landlubber-key
./hcloud ssh-key create --name landlubber-key --public-key-from-file $1
