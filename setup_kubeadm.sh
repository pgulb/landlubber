#!/usr/bin/env bash

# $1 = 0/1 - kubeadm init or join

# disable SELinux and set network forwarding
# needed for Kubernetes to work correctly
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
sysctl -p

# add kubernetes and docker repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/vKUBE_VER/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/vKUBE_VER/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# install kubeadm and utils
sudo dnf install -y epel-release
sudo dnf install -y dnf-plugins-core htop tar bash-completion
sudo dnf install -y kubelet kubeadm kubectl docker-ce docker-ce-cli --disableexcludes=kubernetes
systemctl enable --now kubelet

# download cri-dockerd
wget https://github.com/Mirantis/cri-dockerd/releases/download/vCRI_DOCKERD_VER/cri-dockerd-CRI_DOCKERD_VER.arm64.tgz
tar -xf cri-dockerd-CRI_DOCKERD_VER.arm64.tgz
mv cri-dockerd/cri-dockerd /usr/local/bin
rm -rf ./cri-dockerd/ cri-dockerd-CRI_DOCKERD_VER.arm64.tgz

# configure cri-docker service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
sudo mv cri-docker.socket cri-docker.service /etc/systemd/system/
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
systemctl start docker
systemctl enable docker
systemctl start cri-docker

# run kubeadm init or join
case $1 in
    0)
        echo "***Running kubeadm init***"
        kubeadm init --config ./kubeadm_conf.yml
        kubeadm init phase upload-certs --upload-certs

        # install calico, enable pod scheduling, install metrics server
        sleep 60
        echo 'source <(kubectl completion bash)' >> ~/.bashrc
        echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
        export KUBECONFIG=/etc/kubernetes/admin.conf
        kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
        kubectl taint nodes --all node-role.kubernetes.io/control-plane-
        kubectl label nodes --all node.kubernetes.io/exclude-from-external-load-balancers-
        sleep 30
        kubectl get csr | grep -E 'Pending' | awk '{print $1}' | xargs -I {} kubectl certificate approve {}
        kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
        clear
        kubectl get all -A
        ;;
    1)
        echo "Running kubeadm join in next create.sh step"
        ;;
    *)
        echo "Error - no parameter passed"
        exit 1
        ;;
esac
