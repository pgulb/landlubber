#!/usr/bin/env bash

if ls ./*.pub 1> /dev/null 2>&1; then
    echo "Keys already exist, skipping ed25519 key generation"
else
    mkdir -p ./output/ &&
    ssh-keygen -t ed25519 -f ./id_ed25519 -N "" -C "landlubber" &&
    cp ./id_ed25519 ./output/ &&
    cp ./id_ed25519.pub ./output/
fi
