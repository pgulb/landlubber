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

./create.sh 1 $PRIVKEY $NODE1
./sign_csrs.sh 1 $PRIVKEY
./create.sh 2 $PRIVKEY $NODE2
./sign_csrs.sh 1 $PRIVKEY
./create.sh 3 $PRIVKEY $NODE3
./sign_csrs.sh 1 $PRIVKEY
sleep 30

./pretty_log.sh "Provisioning services with kubectl and helm"
./provision_services.sh

./pretty_log.sh "Rebooting nodes"
./hcloud server reboot $NODE1
./hcloud server reboot $NODE2
./hcloud server reboot $NODE3
sleep 240

chown -R $HOST_UID:$HOST_GID ./output/
./pretty_log.sh "------------------------------------------------------------------"
./pretty_log.sh "DONE"
./pretty_log.sh "You can run this to connect by SSH: (to node #1)"
./pretty_log.sh "docker run --rm -it -v ./.env:/landlubber/.env:ro -v ./output:/landlubber/output ghcr.io/pgulb/landlubber:main ./connect.sh 1"
if [ "$INSTALL_K8S_DASHBOARD" = "1" ]; then
    ./pretty_log.sh "Command to port-forward dashboard:"
    ./pretty_log.sh "kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 &"
    ./pretty_log.sh "https://localhost:8443"
    ./pretty_log.sh "You can find token for dashboard inside output/dashboard_token"
fi
if [ "$INSTALL_LONGHORN" = "1" ]; then
    ./pretty_log.sh "You can view Longhorn dashboard by running:"
    ./pretty_log.sh "kubectl port-forward service/longhorn-frontend 8080:80 -n longhorn-system &"
    ./pretty_log.sh "http://localhost:8080"
    if [ "$INSTALL_VICTORIA_METRICS" = "1" ]; then
        ./pretty_log.sh "You can view Grafana dashboard by running:"
        ./pretty_log.sh "kubectl port-forward service/vm-grafana 3000:80 -n victoria-metrics &"
        ./pretty_log.sh "http://localhost:3000"
        ./pretty_log.sh "Grafana user is admin, password is in output/grafana_pass"
    fi
fi
./pretty_log.sh "Be patient while pods are starting up"
./pretty_log.sh "------------------------------------------------------------------"
