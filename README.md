# landlubber
  
<img src="./landlubber_logo.svg" alt="logo" align="center" width="512" height="512"/>
  
Docker image tailored for creating 3-node `k3s` ☸️ cluster on Hetzner Cloud  
Machines are cheap CAX11 `arm64` VMs (2 cores, 4GB RAM, 40GB disk)  
Monthly cost - ~13,53€ (3 x 4.51) - verify on https://www.hetzner.com/cloud/  
VMs are created in 3 zones, by default fsn1, nbg1, hel1 🌐  
  
## features
`Landlubber` is powered by 🅰️ Ansible  
  
Optional k8s components include:
- Longhorn (CSI provider) - https://longhorn.io/
- VictoriaMetrics with Grafana - https://victoriametrics.com/
- k8s Dashboard - https://github.com/kubernetes/dashboard
- event-exporter (Slack notifications) - https://github.com/resmoio/kubernetes-event-exporter
- kubetail (web log explorer) - https://github.com/kubetail-org/kubetail
  
You can limit which components will be installed to save compute resources  
Instead of dashboard k9s or Monokle can be utilized  
  
## usage 🛠️
### Prerequisites
- `docker` running  
- `task` (taskfile processor) - https://taskfile.dev/installation/  
- Hetzner Cloud API token
  
Optional:  
- kubectl (port-forwarding)  
- xdg-open (to automatically open forwarded UIs in browser)  
- Slack token (for event-exporter) - https://api.slack.com/tutorials/tracks/getting-a-token
- curl  
- jq  
  
---
### Cluster Deployment  
You can download latest Taskfile.yml (the one with uppercase T) if you have `curl` and `jq` using  
(or just grab it manually from newest tag)  
```shell
ver=$(curl -s https://api.github.com/repos/pgulb/landlubber/tags | jq -r '.[0].name'); curl -Of "https://raw.githubusercontent.com/pgulb/landlubber/$ver/Taskfile.yml"
```
  
Then start with creating default config file - inventory.yml to ./output directory  
```shell
task init
```
  
After typing your hcloud token in that file and making any wanted changes, you can deploy cluster  
```shell
task deploy
```
  
When your cluster is ready, you can copy .kubeconfig file to ~/.kube
```shell
task install-kubeconfig
```
  
You are all set 🚀  
   
---
If you want to view all avalaible tasks, simply run
```shell
task
```
There are some tasks useful after deployment, for example port-forwarding grafana service:
```shell
task grafana
```
## upgrade ⚡
  
Consider k8s version skew before upgrade - https://kubernetes.io/releases/version-skew-policy/  
  
```shell
task upgrade-k3s
```
  
## cleanup 🧹
  
To remove existing VMs and clean output files, run  
  
```shell
task cleanup
```
  
## local k3d  
  
You can setup local 3-node k3d cluster with  
  
```shell
task spin-local-k3d
```
  
and then remove it with  
  
```shell
task delete-local-k3d
```
  
Cluster will be equipped with all apps except Longhorn (not supported by k3d)  
Port-forwarding tasks work for this cluster just like for cloud-based one  
  