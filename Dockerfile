# tleyden5iwx/caffe-cpu-master
# https://registry.hub.docker.com/u/tleyden5iwx/caffe-cpu-master/


FROM ubuntu:14.04


ENV PYTHONPATH /opt/caffe/python

# Add caffe binaries to path
ENV PATH $PATH:/opt/caffe/.build_release/tools

# Get dependencies
RUN apt-get update && apt-get install -y \
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
RUN update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-4.6 30 && \
 update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-4.6 30 && \
 update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 30 && \
 update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.6 30



# Clone the Caffe repo
RUN cd /opt && git clone https://github.com/BVLC/caffe.git


# Glog
RUN cd /opt && wget https://google-glog.googlecode.com/files/glog-0.3.3.tar.gz && \
 tar zxvf glog-0.3.3.tar.gz && \
 cd /opt/glog-0.3.3 && \
 ./configure && \
 make && \
 make install

# Workaround for error loading libglog:
#   error while loading shared libraries: libglog.so.0: cannot open shared object file
# The system already has /usr/local/lib listed in /etc/ld.so.conf.d/libc.conf, so
# running `ldconfig` fixes the problem (which is simpler than using $LD_LIBRARY_PATH)
# TODO: looks like this needs to be run _every_ time a new docker instance is run,
#       so maybe LD_LIBRARY_PATh is a better approach (or add call to ldconfig in ~/.bashrc)
RUN ldconfig

# Gflags
RUN cd /opt && \
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

# Build Caffe core
RUN cd /opt/caffe && \
 cp Makefile.config.example Makefile.config && \
 echo "CPU_ONLY := 1" >> Makefile.config && \
 echo "CXX := /usr/bin/g++-4.6" >> Makefile.config && \
 sed -i 's/CXX :=/CXX ?=/' Makefile && \
 make all

# Add ld-so.conf so it can find libcaffe.so
ADD caffe-ld-so.conf /etc/ld.so.conf.d/

# Run ldconfig again (not sure if needed)
RUN ldconfig

# Install python deps
RUN cd /opt/caffe && \
 (for req in $(cat python/requirements.txt); do pip install $req; done) &&\
 easy_install numpy && \
 (for req in $(cat python/requirements.txt); do pip install $req; done) &&\ 
 easy_install pillow

# Numpy include path hack - github.com/BVLC/caffe/wiki/Setting-up-Caffe-on-Ubuntu-14.04
RUN ln -s /usr/local/lib/python2.7/dist-packages/numpy/core/include/numpy /usr/include/python2.7/numpy

# Build Caffe python bindings
RUN cd /opt/caffe && make pycaffe

# Make + run tests
RUN cd /opt/caffe && make test && make runtest

# sshd
# https://docs.docker.com/examples/running_ssh_service/
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]