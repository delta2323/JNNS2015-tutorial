#!/usr/bin/env bash

(docker run -d -p 22 --name=caffe_chainer delta2323/jnns2015-tutorial && sleep 2) >/dev/null 2>&1 || (docker start caffe_chainer && sleep 2) >/dev/null 2>&1
