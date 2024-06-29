#!/bin/bash

echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'export KUBECONFIG=/landlubber/output/.kubeconfig' >> ~/.bashrc
echo "source <(helm completion bash)" >> ~/.bashrc
source <(helm completion bash)
echo "export KUBECONFIG=/landlubber/output/.kubeconfig" >> ~/.bashrc
export KUBECONFIG=/landlubber/output/.kubeconfig

source ./default.env &&
source ./.env &&

if [ "$INSTALL_METHOD" = "kubeadm" ]; then
    ./pretty_log.sh "With kubeadm-deployed cluster use at your own risk"
    sleep 3
fi

if [ "$#" -ne 1 ]; then
    ./pretty_log.sh "Usage: $0 <k3s_version>"
    ./pretty_log.sh "The latest version is:"
    ./pretty_log.sh "$(curl -sL https://api.github.com/repos/rancher/k3s/releases/latest | jq -r '.tag_name')"
    ./pretty_log.sh "ENSURE YOU CAN MANAGE DOWNTIME IF YOU UPDATE MORE THAN ONE MINOR VERSION!"
    exit 1
fi

./pretty_log.sh "Running k3s update"
./pretty_log.sh "Updating to $1"
./pretty_log.sh "Version skew for control plane is one minor version"
./pretty_log.sh "ENSURE YOU CAN MANAGE DOWNTIME IF YOU UPDATE MORE THAN ONE MINOR VERSION!"
sleep 10 &&

./pretty_log.sh "Deleting old update plan if exists"
kubectl -n system-upgrade delete plans.upgrade.cattle.io server-plan
cp ./update_plan_fixed_ver.template ./update_plan_fixed_ver.yml &&
sed -i s/K3S_NEW_VERSION/$1/g ./update_plan_fixed_ver.yml &&
kubectl apply -f update_plan_fixed_ver.yml &&
rm ./update_plan_fixed_ver.yml
./pretty_log.sh "Update in progress"
./pretty_log.sh "See progress using:"
./pretty_log.sh "kubectl -n system-upgrade get plans.upgrade.cattle.io -o yaml"
./pretty_log.sh "Or just:"
./pretty_log.sh "kubectl get no -w (it will disconnect when current api server goes down)"
