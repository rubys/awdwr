FROM ubuntu:18.04
ENV DEBIAN_FRONTEND noninteractive

# generate locales
ENV LANG en_US.UTF-8

RUN apt-get update -y && \
    apt-get install -y curl sudo software-properties-common &&\
    (curl -sL https://deb.nodesource.com/setup_11.x | \
       sudo -E bash -) && \
    apt-get update -y && \
    apt-get install -y nodejs locales && \
    locale-gen $LANG

RUN apt-get install -y \
  git vim ruby lsof \
  libgmp3-dev \
  libmysqlclient-dev \
  libxslt-dev libxml2-dev \
  libpq-dev \
  zlib1g-dev

RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys \
  409B6B1796C275462A1703113804BB82D39DC0E3 \
  7D2BAF1CF37B13E2069D6956105BD0E739499BDB &&\
  /usr/bin/curl -sSL https://get.rvm.io | bash -s stable &&\
  /bin/bash -l -c "rvm requirements"

RUN useradd -ms /bin/bash awdwr &&\
  adduser awdwr rvm &&\
  adduser awdwr sudo &&\
  echo "awdwr ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/awdwr

WORKDIR /home/awdwr
ENV HOME /home/awdwr
ENV USER awdwr
USER awdwr

RUN /bin/bash -l -c "rvm install 2.6.1" &&\
  /bin/bash -l -c "rvm use 2.6.1"

ADD docker-setup common-setup /home/awdwr/
RUN /bin/bash -l -c "source docker-setup"
EXPOSE 3000
