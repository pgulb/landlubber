#!/usr/bin/env bash

./pretty_log.sh "Running wrapper.sh"
source ./default.env &&
source ./.env &&
./generate_ed25519.sh &&
./init_hcloud.sh $PUBKEY $HCLOUD_TOKEN 1 &&

sed -i s/KUBE_VER/$KUBE_VER/g ./setup_kubeadm.sh &&
sed -i s/CRI_DOCKERD_VER/$CRI_DOCKERD_VER/g ./setup_kubeadm.sh &&
sed -i s@SLACK_TOKEN@$SLACK_TOKEN@g ./event_exp_config.yml &&
sed -i s@SLACK_CHANNEL_NAME@$SLACK_CHANNEL_NAME@g ./event_exp_config.yml &&
sed -i s+NODE1+$NODE1+g ./setup_kubeadm.sh &&
sed -i s+NODE2+$NODE2+g ./setup_kubeadm.sh &&
sed -i s+NODE3+$NODE3+g ./setup_kubeadm.sh &&

./create.sh 1 $PRIVKEY $NODE1 $INSTALL_K8S_DASHBOARD $INSTALL_EVENT_EXPORTER $INSTALL_LONGHORN &&
./create.sh 2 $PRIVKEY $NODE2 &&
./create.sh 3 $PRIVKEY $NODE3 &&
./sign_csrs.sh 1 $PRIVKEY &&

./hcloud server reboot $NODE1
./hcloud server reboot $NODE2
./hcloud server reboot $NODE3
sleep 60

scp -i $PRIVKEY -o StrictHostKeyChecking=no \
    ./rollout.sh root@$(cat ./output/public_ipv4-1):/root/
ssh -i $PRIVKEY -o StrictHostKeyChecking=no root@$(cat ./output/public_ipv4-1) \
    '/root/rollout.sh > /root/rollout.log 2>&1'
scp -i $PRIVKEY -o StrictHostKeyChecking=no \
    root@$(cat ./output/public_ipv4-1):/root/rollout.log \
    ./output/rollout.log

chown -R $HOST_UID:$HOST_GID ./output/
./pretty_log.sh "------------------------------------------------------------------"
./pretty_log.sh "DONE"
./pretty_log.sh "You can run this to connect by SSH: (to node #1)"
./pretty_log.sh "docker run --rm -it -v ./.env:/landlubber/.env:ro -v ./output:/landlubber/output ghcr.io/pgulb/landlubber:main ./connect.sh 1"
if [ "$INSTALL_K8S_DASHBOARD" = "1" ]; then
    ./pretty_log.sh "Command to port-forward dashboard:"
    ./pretty_log.sh "kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 &"
    ./pretty_log.sh "You can find token for dashboard inside dashboard_token file in output"
fi
if [ "$INSTALL_LONGHORN" = "1" ]; then
    ./pretty_log.sh "You can view Longhorn dashboard by running:"
    ./pretty_log.sh "kubectl port-forward service/longhorn-frontend 8080:80 -n longhorn-system &"
fi
./pretty_log.sh "------------------------------------------------------------------"
