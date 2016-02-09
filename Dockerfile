FROM ubuntu:14.04.3
ENV DEBIAN_FRONTEND noninteractive

# generate locales
ENV LANG en_US.UTF-8
RUN locale-gen $LANG

RUN apt-get install -y software-properties-common && \
    apt-get install -y curl &&\
    (curl -sL https://deb.nodesource.com/setup_5.x | \
       sudo -E bash -) && \
    apt-get update -y && \
    apt-get install -y nodejs

RUN apt-get install -y \
  git \
  libgmp3-dev \
  libmysqlclient-dev \
  libpq-dev \
  zlib1g-dev

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys \
  409B6B1796C275462A1703113804BB82D39DC0E3

RUN /usr/bin/curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"

RUN useradd -ms /bin/bash awdwr
RUN adduser awdwr rvm
RUN adduser awdwr sudo
RUN echo "awdwr ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/awdwr

WORKDIR /home/awdwr
ENV HOME /home/awdwr
ENV USER awdwr
USER awdwr

RUN /bin/bash -l -c "rvm install 2.3.0"
RUN /bin/bash -l -c "rvm use 2.3.0"

ADD rdb-setup /home/awdwr/
RUN /bin/bash -l -c "source rdb-setup"
EXPOSE 3000
