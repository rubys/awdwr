FROM quay.io/centos/centos:stream9
RUN yum install -y \
  gcc \
  git \
  redis \
  ruby-devel \
  sqlite-devel \
  which
RUN yum reinstall -y tzdata
RUN gem install rails
RUN rails new depot


# RUN rails new depot --skip-bundle
# WORKDIR depot
# RUN bundle remove tzinfo-data
# RUN bundle add tzinfo-data
# RUN bundle binstubs bundler
# RUN bin/rails importmap:install turbo:install stimulus:install

CMD ["/bin/bash"]
