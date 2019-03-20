FROM ubuntu:18.04
ENV DEBIAN_FRONTEND noninteractive

# generate locales
ENV LANG en_US.UTF-8

RUN apt-get update -y && \
    apt-get install -y curl sudo software-properties-common &&\
    (curl -sL https://deb.nodesource.com/setup_11.x | \
       sudo -E bash -) && \
    (curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -) &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | \
      sudo tee /etc/apt/sources.list.d/yarn.list &&\
    apt-get update -y && \
    apt-get install -y nodejs locales yarn && \
    locale-gen $LANG

RUN gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys \
  409B6B1796C275462A1703113804BB82D39DC0E3 \
  7D2BAF1CF37B13E2069D6956105BD0E739499BDB &&\
  /usr/bin/curl -sSL https://get.rvm.io | bash -s stable &&\
  /bin/bash -l -c "rvm requirements"

RUN useradd -ms /bin/bash awdwr &&\
  adduser awdwr rvm &&\
  adduser awdwr sudo &&\
  echo "awdwr ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/awdwr

RUN apt-get install -y \
  git vim ruby lsof rsync tzdata \
  chromium-chromedriver \
  libgmp3-dev \
  libmysqlclient-dev \
  libxslt-dev libxml2-dev \
  libpq-dev \
  zlib1g-dev

RUN /bin/bash -l -c "rvm install 2.6.2" &&\
  /bin/bash -l -c "rvm use 2.6.2"

WORKDIR /home/awdwr
ENV HOME /home/awdwr
ENV USER awdwr
USER awdwr

ADD docker-setup common-setup /home/awdwr/
RUN /bin/bash -l -c "source docker-setup"
EXPOSE 3333 3334
