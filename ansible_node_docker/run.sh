#!/usr/bin/env bash

docker rm -f rocky
docker run --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:rw --cgroupns=host \
--name rocky -p 127.0.0.1:2222:22 -d ssh:1
sleep 3
docker exec rocky sh -c 'systemctl enable sshd && systemctl start sshd'
