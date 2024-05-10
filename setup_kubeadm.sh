#!/usr/bin/env bash

# $1 = 0/1 - kubeadm init or join
# $2 = INSTALL_K8S_DASHBOARD
# $3 = INSTALL_EVENT_EXPORTER
# $4 = INSTALL_LONGHORN
# $5 = INSTALL_METRICS_SERVER

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
        sleep 150

        # add kubectl completion and point kubectl to the admin.conf
        echo 'source <(kubectl completion bash)' >> ~/.bashrc
        echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
        export KUBECONFIG=/etc/kubernetes/admin.conf

        # install calico        
        kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml
        curl https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml -O
        sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 10.244.0.0\/16/g' custom-resources.yaml
        kubectl create -f custom-resources.yaml
        sleep 150

        # enable pod scheduling
        kubectl taint nodes --all node-role.kubernetes.io/control-plane-
        kubectl label nodes --all node.kubernetes.io/exclude-from-external-load-balancers-
        sleep 30

        if [ "$5" = "1" ]; then
            # install metrics-server
            kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
            sleep 30
        fi

        if [ "$2" = "1" ]; then
            # install kubernetes-dashboard
            helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
            helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
            --create-namespace --namespace kubernetes-dashboard
            kubectl apply -f ./dashboard_user.yml
            sleep 15
            kubectl -n kubernetes-dashboard create token admin-user > ./dashboard_token
        fi

        if [ "$3" = "1" ]; then
            # install event-exporter
            kubectl apply -f ./event_exp_config.yml
            kubectl apply -f ./event_exporter.yml
        fi

        if [ "$4" = "1" ]; then
            # install Longhorn
            kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.1/deploy/longhorn.yaml
            sleep 60
        fi

        echo "-----[-----init complete-----]-----"
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
