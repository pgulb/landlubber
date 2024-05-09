#!/usr/bin/env bash

# $1 = node number to provision
# $2 = $PRIVKEY
# $3 = node name
# $4 = INSTALL_K8S_DASHBOARD
# $5 = INSTALL_EVENT_EXPORTER

ip4=""
./pretty_log.sh "Running create.sh"

function create_vm() {
    ./pretty_log.sh "Creating VM $3"
    mkdir -p ./output &&
    ./hcloud server create --network landlubber --location fsn1 --ssh-key landlubber-key \
    --name "$3" --type cax11 --image rocky-9 -o json \
    | jq -r '.server.public_net.ipv4.ip' | tr -d "\n" > ./output/public_ipv4-$1 &&
    sleep 30
}

function get_ip4() {
    ./pretty_log.sh "Getting IP4 for $3"
    ip4=$(cat ./output/public_ipv4-$1)
}

function kubeadm_init() {
    ./pretty_log.sh "Running kubeadm init on $3, this may take a while"
    sed -i s/CONTROL_PLANE_ENDPOINT/$ip4/g ./kubeadm_conf.yml &&
    scp -i $2 -o StrictHostKeyChecking=no \
    ./setup_kubeadm.sh root@$ip4:/root/ &&
    scp -i $2 -o StrictHostKeyChecking=no \
    ./*.yml root@$ip4:/root/ &&
    scp -i $2 -o StrictHostKeyChecking=no \
    ./dashboard_user.yml root@$ip4:/root/ &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    "/root/setup_kubeadm.sh 0 $4 $5 > /root/setup_kubeadm.log 2>&1 && \
    rm -f /root/setup_kubeadm.sh /root/kubeadm_conf.yml"
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    'grep -B1 discovery-token-ca-cert-hash /root/setup_kubeadm.log | tail -2 | sed \
    "s+--token+--cri-socket unix:///var/run/cri-dockerd.sock --token+" > /root/kubeadm_join.sh && \
    chmod +x /root/kubeadm_join.sh'
    ./pretty_log.sh "kubeadm init on $3 complete"
}

function kubeadm_join() {
    ./pretty_log.sh "Running kubeadm join on $3, this may take a while"
    scp -i $2 -o StrictHostKeyChecking=no \
    ./setup_kubeadm.sh root@$ip4:/root/ &&
    scp -i $2 -o StrictHostKeyChecking=no \
    ./output/kubeadm_join.sh root@$ip4:/root/ &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    '/root/setup_kubeadm.sh 1 > /root/setup_kubeadm.log 2>&1 &&
    /root/kubeadm_join.sh >> /root/setup_kubeadm.log 2>&1' &&
    rm -f /root/setup_kubeadm.sh /root/kubeadm_join.sh
}

function download_outputs() {
    ./pretty_log.sh "Downloading outputs for $3"

    case $1 in
    1)
        scp -i $2 -o StrictHostKeyChecking=no \
        root@$ip4:/root/setup_kubeadm.log \
        ./output/setup_kubeadm.log-$1 &&
        scp -i $2 -o StrictHostKeyChecking=no \
        root@$ip4:/etc/kubernetes/admin.conf \
        ./output/.kubeconfig &&
        scp -i $2 -o StrictHostKeyChecking=no \
        root@$ip4:/root/kubeadm_join.sh \
        ./output/kubeadm_join.sh
        if [ "$4" = "1" ]; then
            scp -i $2 -o StrictHostKeyChecking=no \
            root@$ip4:/root/dashboard_token \
            ./output/dashboard_token
        fi
        ;;

    2 | 3)
        scp -i $2 -o StrictHostKeyChecking=no \
        root@$ip4:/root/setup_kubeadm.log \
        ./output/setup_kubeadm.log-$1
        ;;

    *)
        echo "Wrong param for download_outputs"
        exit 1
        ;;
    esac
}

case $1 in
    1)
        create_vm $@
        get_ip4 $@
        kubeadm_init $@
        download_outputs $@
        ;;

    2 | 3)
        create_vm $@
        get_ip4 $@
        kubeadm_join $@
        download_outputs $@
        ;;

    *)
        echo "Use to provision node 1, 2 or 3"
        echo "ERROR on create.sh"
        exit 1
        ;;
esac
