# landlubber

Dockerized script collection to provision 3-node Kubernetes cluster on Hetzner CAX11 VMs

## usage

Create .env file with HCLOUD_TOKEN and any values you would wish to ovveride from default.env

If you want to use existing SSH key, add them to KUBKEY and PRIVKEY in .env and attach as volumes just like .env to /landlubber directory

```shell
docker run --rm -v ./.env:/landlubber/.env:ro ghcr.io/pgulb/landlubber:main
```

## cleanup

To remove existing VMs, run

```shell
docker run --rm -v ./.env:/landlubber/.env:ro ghcr.io/pgulb/landlubber:main ./remove.sh
```
