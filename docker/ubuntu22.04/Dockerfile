FROM arm64v8/ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y && apt-get install -y \
  build-essential \
  git \
  libsqlite3-dev \
  redis \
  ruby-dev \
  tzdata
RUN gem install rails
RUN rails new depot
CMD ["bash"]
