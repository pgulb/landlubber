#!/usr/bin/env bash

# disable SELinux and set network forwarding
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
sysctl -p

# add IPs from private hetzner network to hosts file
cat <<EOF | tee -a /etc/cloud/templates/hosts.redhat.tmpl
10.10.0.2  NODE1
10.10.0.3  NODE2
10.10.0.4  NODE3
EOF
cat <<EOF | tee -a /etc/hosts
10.10.0.2  NODE1
10.10.0.3  NODE2
10.10.0.4  NODE3
EOF

# install packages
dnf install -q -y epel-release
dnf install -q -y dnf-plugins-core htop tar bash-completion git vim jq iscsi-initiator-utils nfs-utils
systemctl start iscsid
systemctl enable iscsid
systemctl stop rpcbind
systemctl disable rpcbind
systemctl stop rpcbind.socket
systemctl disable rpcbind.socket

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -f ./get_helm.sh
