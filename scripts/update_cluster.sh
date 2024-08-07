#!/bin/bash

latest=$(curl -sL https://api.github.com/repos/rancher/k3s/releases/latest | jq -r '.tag_name')
kubectl -n system-upgrade delete plans.upgrade.cattle.io server-plan
sed -i s/K3S_NEW_VERSION/$latest/g ./manifests/update_plan_fixed_ver.yml &&
kubectl apply -f ./manifests/update_plan_fixed_ver.yml
echo
echo "---"
echo "Update in progress..."
echo "See progress using:"
echo "kubectl -n system-upgrade get plans.upgrade.cattle.io -o yaml"
echo "Or just:"
echo "kubectl get no -w (it will disconnect when current api server goes down)"
