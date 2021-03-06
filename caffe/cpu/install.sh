#!/usr/bin/env bash

# Summary
# * Install Caffe to /opt/caffe
# * Add caffe user
# Note
# * This script need root privilege
# * We verify installation procedure with gcc4.6
# Credit
# * original is from https://registry.hub.docker.com/u/tleyden5iwx/caffe-cpu-master/dockerfile/

PYTHONPATH=/opt/caffe/python:$PYTHONPATH
# Add caffe binaries to path
PATH=$PATH:/opt/caffe/.build_release/tools

# Get dependencies
apt-get update
apt-get upgrade -y
apt-get install -y \
 bc \
 cmake \
 curl \
 gcc-4.6 \
 g++-4.6 \
 gcc-4.6-multilib \
 g++-4.6-multilib \
 gfortran \
 git \
 libprotobuf-dev \
 libleveldb-dev \
 libsnappy-dev \
 libopencv-dev \
 libboost-all-dev \
 libhdf5-serial-dev \
 liblmdb-dev \
 libjpeg62 \
 libfreeimage-dev \
 libatlas-base-dev \
 pkgconf \
 protobuf-compiler \
 python-dev \
 python-pip \
 unzip \
 wget

# Use gcc 4.6
update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-4.6 30 && \
 update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-4.6 30 && \
 update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 30 && \
 update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.6 30

# Glog
cd /opt && wget https://google-glog.googlecode.com/files/glog-0.3.3.tar.gz && \
 tar zxvf glog-0.3.3.tar.gz && \
 cd /opt/glog-0.3.3 && \
 ./configure && \
 make && \
 make install

# Workaround for error loading libglog:
#   error while loading shared libraries: libglog.so.0: cannot open shared object file
# The system already has /usr/local/lib listed in /etc/ld.so.conf.d/libc.conf, so
# running `ldconfig` fixes the problem (which is simpler than using $LD_LIBRARY_PATH)
ldconfig

# Gflags
cd /opt && \
 wget https://github.com/schuhschuh/gflags/archive/master.zip && \
 unzip master.zip && \
 cd /opt/gflags-master && \
 mkdir build && \
 cd /opt/gflags-master/build && \
 export CXXFLAGS="-fPIC" && \
 cmake .. && \
 make VERBOSE=1 && \
 make && \
 make install

# Disable driver. This is workaroud for error on libdc1394
# This error happen when creating mnist data
# See: http://stackoverflow.com/questions/12689304/ctypes-error-libdc1394-error-failed-to-initialize-libdc1394/26028597#26028597
ln /dev/null /dev/raw1394



# Clone the Caffe repo
cd /opt && git clone https://github.com/BVLC/caffe.git

# Build Caffe core
cd /opt/caffe && \
 cp Makefile.config.example Makefile.config && \
 echo "CPU_ONLY := 1" >> Makefile.config && \
 echo "CXX := /usr/bin/g++-4.6" >> Makefile.config && \
 sed -i 's/CXX :=/CXX ?=/' Makefile && \
 make all

# Add ld-so.conf so it can find libcaffe.so
echo '/opt/caffe/.build_release/lib/' >> /etc/ld.so.conf.d/
ldconfig

# Install python deps
cd /opt/caffe && \
 (for req in $(cat python/requirements.txt); do pip install $req; done) &&\
 easy_install numpy && \
 (for req in $(cat python/requirements.txt); do pip install $req; done) &&\ 
 easy_install pillow

# Numpy include path hack - github.com/BVLC/caffe/wiki/Setting-up-Caffe-on-Ubuntu-14.04
ln -s /usr/local/lib/python2.7/dist-packages/numpy/core/include/numpy /usr/include/python2.7/numpy

# Build Caffe python bindings
cd /opt/caffe && make pycaffe

# Make + run tests
cd /opt/caffe && make test && make runtest



# add caffe user
useradd -m -d /home/caffe -s /bin/bash caffe \
 && echo "caffe:caffe" | chpasswd \
 && mkdir /home/caffe/.ssh \
 && chmod 700 /home/caffe/.ssh \
 && cp /root/.ssh/authorized_keys /home/caffe/.ssh \
 && chmod 600 /home/caffe/.ssh/authorized_keys \
 && chown -R caffe:caffe /home/caffe/.ssh
echo "caffe ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo 'export PATH=$PATH:/opt/caffe/.build_release/tools' >> /home/caffe/.bashrc
echo 'PYTHONPATH=$PYTHONPATH/opt/caffe/python' >> /home/caffe/.bashrc

# various files are created by root. Change ownership
chown caffe:caffe -R /opt/caffe/
