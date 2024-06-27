# landlubber

Dockerized script collection to provision 3-node Kubernetes ☸️ cluster on Hetzner CAX11 VMs  
Monthly cost - 13,53€ (3 x 4.51) - check on https://www.hetzner.com/cloud/  
  
You can choose between k3s and kubeadm, with k3s recommended  
k3s is lighter and comes with HA - all nodes are schedulable control plane  
kubeadm is more 'mature' k8s deployment, but is more heavy, and it is installed with control
plane only on node #1  
k3s installation is also much faster 🚀  
  
VMs are created in 3 zones: fsn1, nbg1, hel1 🌐  
  
Optional components to install:
- metrics-server - https://github.com/kubernetes-sigs/metrics-server
- Longhorn (CSI provider) - https://longhorn.io/
- VictoriaMetrics with Grafana - https://victoriametrics.com/
- k8s Dashboard - https://github.com/kubernetes/dashboard
- event-exporter - https://github.com/resmoio/kubernetes-event-exporter
- kubetail (web log explorer) - https://github.com/kubetail-org/kubetail
  
Do not install components if you do not need them, resources are quite limited  
Instead of dashboard one can use k9s or Monokle  
  
## usage 🛠️
  
Create .env file with HCLOUD_TOKEN and INSTALL_METHOD with either k3s or kubeadm  
add any values you would wish to override from default.env  
KUBE_VER and CRI_DOCKERD_VER are used only if using kubeadm  
INSTALL_METRICS_SERVER is regarded also only in kubeadm, k3s installs metrics-server anyway for now
  
If you want to use existing SSH key, add them to PUBKEY and PRIVKEY in .env and add to output
directory which is added with volume in commands below  
  
Attach ./output dir to acquire generated SSH key, logs, kubeconfig file etc
  
```shell
docker run --rm -v ./.env:/landlubber/.env:ro -v ./output:/landlubber/output ghcr.io/pgulb/landlubber:main
```
  
## connecting ⚡
  
You can connect to created node 1 or 2 or 3 by using  
  
```shell
docker run --rm -it -v ./.env:/landlubber/.env:ro -v ./output:/landlubber/output ghcr.io/pgulb/landlubber:main ./connect.sh 1|2|3
```
  
## cleanup 🧹
  
To remove existing VMs and clean output files, run  
  
```shell
docker run --rm -v ./.env:/landlubber/.env:ro -v ./output:/landlubber/output ghcr.io/pgulb/landlubber:main ./remove.sh
```
  