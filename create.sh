#!/usr/bin/env bash

# $1 = node number to provision
# $2 = $PRIVKEY
# $3 = node name
# $4 = install method

ip4=""
./pretty_log.sh "Running create.sh"

function create_vm() {
    case $1 in
    1)
        REGION="fsn1"
        ;;
    2)
        REGION="nbg1"
        ;;
    3)
        REGION="hel1"
        ;;
    esac

    ./pretty_log.sh "Creating VM $3 in $REGION"
    mkdir -p ./output &&
    ./hcloud server create --network landlubber --location $REGION --ssh-key landlubber-key \
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
    ./kubeadm_conf.yml root@$ip4:/root/ &&
    scp -i $2 -o StrictHostKeyChecking=no \
    ./initial_packages.sh root@$ip4:/root/ &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    "/root/initial_packages.sh 2>&1 | tee /root/setup_kubeadm.log" &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    "/root/setup_kubeadm.sh 0 2>&1 | tee /root/setup_kubeadm.log" &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    'grep -B1 discovery-token-ca-cert-hash /root/setup_kubeadm.log | tail -2 | sed \
    "s+--token+--cri-socket unix:///var/run/cri-dockerd.sock --token+" > /root/kubeadm_join.sh && \
    chmod +x /root/kubeadm_join.sh' &&
    ./pretty_log.sh "kubeadm init on $3 complete"
}

function k3s_init() {
    ./pretty_log.sh "Installing K3S on $3, this may take a while"
    scp -i $2 -o StrictHostKeyChecking=no \
    ./k3s_first.sh root@$ip4:/root/ &&
    scp -i $2 -o StrictHostKeyChecking=no \
    ./initial_packages.sh root@$ip4:/root/ &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    "/root/initial_packages.sh 2>&1 | tee /root/k3s_first.log" &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    "/root/k3s_first.sh 2>&1 | tee /root/k3s_first.log" &&
    ./pretty_log.sh "K3s installation on $3 complete"
}

function k3s_join() {
    ./pretty_log.sh "Installing K3S on $3, this may take a while"
    scp -i $2 -o StrictHostKeyChecking=no \
    ./k3s_join.sh root@$ip4:/root/ &&
    scp -i $2 -o StrictHostKeyChecking=no \
    ./initial_packages.sh root@$ip4:/root/ &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    "/root/initial_packages.sh 2>&1 | tee /root/k3s.log" &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    "/root/k3s_join.sh 2>&1 | tee /root/k3s.log" &&
    ./pretty_log.sh "K3s installation on $3 complete"
}

function kubeadm_join() {
    ./pretty_log.sh "Running kubeadm join on $3, this may take a while"
    scp -i $2 -o StrictHostKeyChecking=no \
    ./setup_kubeadm.sh root@$ip4:/root/ &&
    scp -i $2 -o StrictHostKeyChecking=no \
    ./output/kubeadm_join.sh root@$ip4:/root/ &&
    scp -i $2 -o StrictHostKeyChecking=no \
    ./initial_packages.sh root@$ip4:/root/ &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    "/root/initial_packages.sh 2>&1 | tee /root/setup_kubeadm.log" &&
    ssh -i $2 -o StrictHostKeyChecking=no root@$ip4 \
    '/root/setup_kubeadm.sh 1 2>&1 | tee /root/setup_kubeadm.log &&
    /root/kubeadm_join.sh 2>&1 | tee /root/setup_kubeadm.log' &&
    # rm -f /root/setup_kubeadm.sh /root/kubeadm_join.sh
    ./pretty_log.sh "kubeadm join on $3 complete"
}

function download_outputs() {
    ./pretty_log.sh "Downloading outputs for $3"

    case $1 in
    1)
        if [ "$4" = "kubeadm" ]; then
            scp -i $2 -o StrictHostKeyChecking=no \
            root@$ip4:/root/setup_kubeadm.log \
            ./output/setup_kubeadm.log-$1
            scp -i $2 -o StrictHostKeyChecking=no \
            root@$ip4:/etc/kubernetes/admin.conf \
            ./output/.kubeconfig
            scp -i $2 -o StrictHostKeyChecking=no \
            root@$ip4:/root/kubeadm_join.sh \
            ./output/kubeadm_join.sh
        fi
        if [ "$4" = "k3s" ]; then
            scp -i $2 -o StrictHostKeyChecking=no \
            root@$ip4:/etc/rancher/k3s/k3s.yaml \
            ./output/.kubeconfig
            scp -i $2 -o StrictHostKeyChecking=no \
            root@$ip4:/root/k3s_first.log \
            ./output/k3s.log-$1
            scp -i $2 -o StrictHostKeyChecking=no \
            root@$ip4:/root/k3s_token \
            ./output/k3s_token
        fi
        ;;

    2 | 3)
        if [ "$4" = "kubeadm" ]; then
            scp -i $2 -o StrictHostKeyChecking=no \
            root@$ip4:/root/setup_kubeadm.log \
            ./output/setup_kubeadm.log-$1
        fi
        if [ "$4" = "k3s" ]; then
            scp -i $2 -o StrictHostKeyChecking=no \
            root@$ip4:/root/k3s.log \
            ./output/k3s.log-$1
        fi
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
        if [ "$4" = "kubeadm" ]; then
            kubeadm_init $@
        fi
        if [ "$4" = "k3s" ]; then
            k3s_init $@
        fi
        download_outputs $@
        ;;

    2 | 3)
        create_vm $@
        get_ip4 $@
        if [ "$4" = "kubeadm" ]; then
            kubeadm_join $@
        fi
        if [ "$4" = "k3s" ]; then
            k3s_join $@
        fi
        download_outputs $@
        ;;

    *)
        echo "Use to provision node 1, 2 or 3"
        echo "ERROR on create.sh"
        exit 1
        ;;
esac
