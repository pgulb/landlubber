#!/usr/bin/env bash

# $1 = 0/1 - kubeadm init or join

# disable SELinux and set network forwarding
# needed for Kubernetes to work correctly
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
sysctl -p

# add IPs from private hetzner network to hosts file
cat <<EOF | sudo tee -a /etc/cloud/templates/hosts.redhat.tmpl
10.10.0.2  NODE1
10.10.0.3  NODE2
10.10.0.4  NODE3
EOF
cat <<EOF | sudo tee -a /etc/hosts
10.10.0.2  NODE1
10.10.0.3  NODE2
10.10.0.4  NODE3
EOF

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

# install necessary packages
sudo dnf install -q -y epel-release
sudo dnf install -q -y dnf-plugins-core htop tar bash-completion git vim jq iscsi-initiator-utils nfs-utils
sudo dnf install -q -y kubelet kubeadm kubectl docker-ce docker-ce-cli --disableexcludes=kubernetes
sudo systemctl start iscsid
sudo systemctl enable iscsid
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -f ./get_helm.sh
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
        sleep 100

        # add kubectl/helm completion and point kubectl to the admin.conf
        echo 'source <(kubectl completion bash)' >> ~/.bashrc
        echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
        echo "source <(helm completion bash)" >> ~/.bashrc

        ############################
        # Rest of installation moved to provision_services.sh
        ############################

        echo "-----[X]-----init complete-----[X]-----"
        exit 0
        ;;
    1)
        echo "Running kubeadm join in next create.sh step"
        exit 0
        ;;
    *)
        echo "Error - no parameter passed"
        exit 1
        ;;
esac
