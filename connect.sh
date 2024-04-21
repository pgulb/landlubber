#!/usr/bin/env bash

case $1 in

    1 | 2 | 3)
        ssh -i $2 -o StrictHostKeyChecking=no root@$(cat ./output/public_ipv4-$1)
        ;;

    *)
        echo "Use to connect to node 1, 2 or 3"
        echo "Usage: $0 {1|2|3}"
        exit 1
        ;;
esac