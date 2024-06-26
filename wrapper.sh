#!/usr/bin/env bash

source ./default.env &&
source ./.env &&

./pretty_log.sh
./pretty_log.sh
./pretty_log.sh " _                 _ _       _     _               "
./pretty_log.sh "| |               | | |     | |   | |              "
./pretty_log.sh "| | __ _ _ __   __| | |_   _| |__ | |__   ___ _ __ "
./pretty_log.sh "| |/ _\` | '_ \ / _\` | | | | | '_ \| '_ \ / _ \ '__|"
./pretty_log.sh "| | (_| | | | | (_| | | |_| | |_) | |_) |  __/ |   "
./pretty_log.sh "|_|\__,_|_| |_|\__,_|_|\__,_|_.__/|_.__/ \___|_|   "
./pretty_log.sh                                                   
./pretty_log.sh                                                   
./pretty_log.sh Landlubber will use $INSTALL_METHOD...
sleep 5

./pretty_log.sh "Running wrapper.sh"
./generate_ed25519.sh &&
./init_hcloud.sh $PUBKEY $HCLOUD_TOKEN 1 &&

sed -i s/KUBE_VER/$KUBE_VER/g ./setup_kubeadm.sh &&
sed -i s/CRI_DOCKERD_VER/$CRI_DOCKERD_VER/g ./setup_kubeadm.sh &&
sed -i s@SLACK_TOKEN@$SLACK_TOKEN@g ./event_exp_config.yml &&
sed -i s@SLACK_CHANNEL_NAME@$SLACK_CHANNEL_NAME@g ./event_exp_config.yml &&
sed -i s+NODE1+$NODE1+g ./initial_packages.sh &&
sed -i s+NODE2+$NODE2+g ./initial_packages.sh &&
sed -i s+NODE3+$NODE3+g ./initial_packages.sh &&
sed -i s+NODE1+$NODE1+g ./k3s_join.sh &&

./create.sh 1 $PRIVKEY $NODE1 $INSTALL_METHOD
if [ "$INSTALL_METHOD" = "kubeadm" ]; then
    ./sign_csrs.sh 1 $PRIVKEY
fi
sed -i s+JOIN_TOKEN+$(cat ./output/k3s_token)+g ./k3s_join.sh &&

./create.sh 2 $PRIVKEY $NODE2 $INSTALL_METHOD
if [ "$INSTALL_METHOD" = "kubeadm" ]; then
    ./sign_csrs.sh 1 $PRIVKEY
fi
./create.sh 3 $PRIVKEY $NODE3 $INSTALL_METHOD
if [ "$INSTALL_METHOD" = "kubeadm" ]; then
    ./sign_csrs.sh 1 $PRIVKEY
fi
sleep 30

sed -i s+127.0.0.1+$(cat ./output/public_ipv4-1)+g ./output/.kubeconfig
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
./pretty_log.sh ".kubeconfig file is in output/ directory"
if [ "$INSTALL_METHOD" = "k3s" ]; then
    ./pretty_log.sh ".kubeconfig points to IP of node #1"
    ./pretty_log.sh "You can change it to point to IP of node #2 or #3"
fi
./pretty_log.sh "IPs are in output/public_ipv4-X files"
./pretty_log.sh "You can run this to connect by SSH: (to node #1)"
./pretty_log.sh "docker run --rm -it -v ./.env:/landlubber/.env:ro -v ./output:/landlubber/output ghcr.io/pgulb/landlubber:main ./connect.sh 1"
./pretty_log.sh
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
./pretty_log.sh
./pretty_log.sh "*** BE PATIENT WHILE PODS ARE STARTING UP 🚀 ***"
./pretty_log.sh "------------------------------------------------------------------"
