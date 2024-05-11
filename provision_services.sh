#!/usr/bin/env bash

source ./default.env &&
source ./.env &&

# enable bash completions
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'export KUBECONFIG=/landlubber/output/.kubeconfig' >> ~/.bashrc
echo "source <(helm completion bash)" >> ~/.bashrc
source <(helm completion bash)
export KUBECONFIG=/landlubber/output/.kubeconfig

# install calico
./pretty_log.sh "Installing calico CNI"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml -O
sed -i 's/cidr: 192\.168\.0\.0\/16/cidr: 10.244.0.0\/16/g' custom-resources.yaml
kubectl create -f custom-resources.yaml
sleep 100

# enable pod scheduling
./pretty_log.sh "Enabling pod scheduling"
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl label nodes --all node.kubernetes.io/exclude-from-external-load-balancers-
sleep 90

if [ "$INSTALL_METRICS_SERVER" = "1" ]; then
    # install metrics-server
    ./pretty_log.sh "Installing metrics-server"
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    sleep 90
fi

if [ "$INSTALL_K8S_DASHBOARD" = "1" ]; then
    # install kubernetes-dashboard
    ./pretty_log.sh "Installing kubernetes-dashboard"
    helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
    helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
    --create-namespace --namespace kubernetes-dashboard
    kubectl apply -f ./dashboard_user.yml
    sleep 90
    kubectl -n kubernetes-dashboard create token admin-user > ./output/dashboard_token
fi

if [ "$INSTALL_LONGHORN" = "1" ]; then
    # install Longhorn
    ./pretty_log.sh "Installing Longhorn"
    kubectl apply -f ./longhorn.yaml
    sleep 120
fi

if [ "$INSTALL_VICTORIA_METRICS" = "1" ]; then
    # install VictoriaMetrics, only if Longhorn is installed
    if [ "$INSTALL_LONGHORN" = "1" ]; then
        ./pretty_log.sh "Installing VictoriaMetrics"
        helm repo add vm https://victoriametrics.github.io/helm-charts/
        helm repo update
        helm install vmcluster vm/victoria-metrics-cluster \
        -f victoria_values.yml --create-namespace -n victoria-metrics
        helm install vmagent vm/victoria-metrics-agent \
        -f vmagent_values.yml -n victoria-metrics
        sleep 150
        # add Grafana to visualize metrics
        helm repo add grafana https://grafana.github.io/helm-charts
        helm repo update
        helm install vm-grafana grafana/grafana -f grafana_values.yml -n victoria-metrics
        sleep 30
        kubectl get secret --namespace victoria-metrics vm-grafana \
            -o jsonpath="{.data.admin-password}" | base64 --decode > ./output/grafana_pass
        export POD_NAME=$(kubectl get pods --namespace victoria-metrics \
            -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=vm-grafana" \
            -o jsonpath="{.items[0].metadata.name}")
        echo -n "kubectl --namespace victoria-metrics port-forward $POD_NAME 3000" > ./output/port_forward_grafana
    else
        ./pretty_log.sh "WARNING: Skipping installing VictoriaMetrics, Longhorn is not installed"
        ./pretty_log.sh "VictoriaMetrics needs persistent storage"
    fi
fi

if [ "$INSTALL_EVENT_EXPORTER" = "1" ]; then
    # install event-exporter
    ./pretty_log.sh "Installing event-exporter"
    kubectl apply -f ./event_exp_config.yml
    kubectl apply -f ./event_exporter.yml
    sleep 60
fi
