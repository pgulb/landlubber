#!/usr/bin/env bash

# Redeploy after all nodes provisioned to rebalance the cluster

# Restarting Deployments
for deployment in $(kubectl get deployments -A -o=jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}'); do
    namespace=$(echo $deployment | cut -d'/' -f1)
    deployment_name=$(echo $deployment | cut -d'/' -f2)
    echo "Restarting deployment $deployment_name in namespace $namespace"
    kubectl rollout restart deployment $deployment_name -n $namespace
done

# Restarting StatefulSets
for statefulset in $(kubectl get statefulsets -A -o=jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}'); do
    namespace=$(echo $statefulset | cut -d'/' -f1)
    statefulset_name=$(echo $statefulset | cut -d'/' -f2)
    echo "Restarting statefulset $statefulset_name in namespace $namespace"
    kubectl rollout restart statefulset $statefulset_name -n $namespace
done
