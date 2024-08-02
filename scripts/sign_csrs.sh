#!/usr/bin/env bash

./pretty_log.sh "Signing certificate requests..."
ssh -i $2 -o StrictHostKeyChecking=no root@$(cat ./output/public_ipv4-$1) \
"kubectl get csr | grep -E 'Pending' | awk '{print \$1}' | xargs -I {} kubectl certificate approve {} > csr.log 2>&1"
