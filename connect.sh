#!/usr/bin/env bash

./pretty_log.sh "Running connect.sh"
source ./default.env &&
source ./.env ;

case $1 in

    1 | 2 | 3)
        ./pretty_log.sh "Connecting to node #$1"
        cp ./output/* ./
        ssh -i $PRIVKEY -o StrictHostKeyChecking=no root@$(cat ./output/public_ipv4-$1)
        ;;

    *)
        echo "Use to connect to node 1, 2 or 3"
        echo "Usage: $0 {1|2|3}"
        exit 1
        ;;
esac
