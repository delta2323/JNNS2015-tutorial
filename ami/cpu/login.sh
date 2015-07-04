#!/usr/bin/env bash

bash admin/docker_start.sh
DOCKER_HOST=`ip -f inet -o addr show docker0|cut -d\  -f 7 | cut -d/ -f 1`
CONTAINER_PORT=`docker inspect -f '{{ if index .NetworkSettings.Ports "22/tcp" }}{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}{{ end }}' caffe_chainer`
ssh root@${DOCKER_HOST} -p ${CONTAINER_PORT}
