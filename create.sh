#!/usr/bin/env bash

# $1 = node number to provision
# $2 = $PRIVKEY
# $3 = node name

ip4=""

function create_vm() {
    echo "Creating VM $3"
    mkdir -p ./output &&
    ./hcloud server create --location fsn1 --ssh-key landlubber-key \
    --name "$3" --type cax11 --image rocky-9 -o json \
    | jq -r '.server.public_net.ipv4.ip' | tr -d "\n" > ./output/public_ipv4-$1 &&
    sleep 30
}

function get_ip4() {
    echo "Getting IP4 for $3"
    ip4=$(cat ./output/public_ipv4-$1)
}

function kubeadm_init() {
    echo "Running kubeadm init on $3"
    scp -i $2 -o StrictHostKeyChecking=no \
    ./setup_kubeadm.sh root@$ip4:/root/ &&
    ssh -i $2  -o StrictHostKeyChecking=no root@$ip4 \
    'chmod +x /root/setup_kubeadm.sh && /root/setup_kubeadm.sh > /root/setup_kubeadm.log 2>&1 && \
    rm -f /root/setup_kubeadm.sh && \
    grep -B1 discovery-token-ca-cert-hash /root/setup_kubeadm.log > /root/kubeadm_join'
}

function kubeadm_join() {
    echo "Running kubeadm join on $3"
    # TODO with kubeadm init
    exit 1
}

function download_outputs() {
    echo "Downloading outputs for $3"
    scp -i $2 -o StrictHostKeyChecking=no \
    root@$ip4:/root/setup_kubeadm.log \
    ./output/setup_kubeadm.log-$ip4 &&
    scp -i $2 -o StrictHostKeyChecking=no \
    root@$ip4:/etc/kubernetes/admin.conf \
    ./output/kubeconfig-$ip4 &&
    scp -i $2 -o StrictHostKeyChecking=no \
    root@$ip4:/root/kubeadm_join \
    ./output/kubeadm_join-$ip4
}

case $1 in
    1)
        create_vm $1 $2 $3
        get_ip4 $1 $2 $3
        kubeadm_init $1 $2 $3
        download_outputs $1 $2 $3
        ;;

    2 | 3)
        create_vm $1 $2 $3
        get_ip4 $1 $2 $3
        kubeadm_join $1 $2 $3
        ;;

    *)
        echo "Use to provision node 1, 2 or 3"
        echo "Usage: $0 {1|2|3} {./private_key} {node_name}"
        exit 1
        ;;
esac
