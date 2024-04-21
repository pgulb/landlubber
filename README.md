# landlubber

Dockerized script collection to provision 3-node Kubernetes cluster on Hetzner CAX11 VMs

## usage

Create .env file with HCLOUD_TOKEN and any values you would wish to ovveride from default.env

If you want to use existing SSH key, add them to KUBKEY and PRIVKEY in .env and attach as volumes just like .env to /landlubber directory

Attach ./output dir to acquire generated SSH key, logs, kubeconfig file etc

```shell
docker run --rm -v ./.env:/landlubber/.env:ro -v ./output:/landlubber/output ghcr.io/pgulb/landlubber:main
```

## connecting

You can connect to created node 1 or 2 or 3 by using

```shell
docker run --rm -it -v ./.env:/landlubber/.env:ro -v ./output:/landlubber/output ghcr.io/pgulb/landlubber:main ./connect.sh 1|2|3
```

## cleanup

To remove existing VMs, run

```shell
docker run --rm -v ./.env:/landlubber/.env:ro ghcr.io/pgulb/landlubber:main ./remove.sh
```
