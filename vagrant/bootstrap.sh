cp /vagrant/02proxy /etc/apt/apt.conf.d

apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install -y apache2 curl git libmysqlclient-dev mysql-server nodejs ruby1.9.3
gem install xmpp4r nokogiri wunderbar

su --login vagrant << 'eof'
  \curl -L https://get.rvm.io | bash -s stable

  mkdir $HOME/git
  cd $HOME/git
  git clone git://github.com/rubys/awdwr.git
  export PATH=$PATH:/usr/sbin
  ruby awdwr/setup.rb

  mkdir bin
  sed "s'/home/rubys'$HOME'" < ~/git/awdwr/testrails.yml > bin/testrails.yml
  cp /vagrant/bin/* bin
eof

export rvm_path=/home/vagrant/.rvm
source $rvm_path/scripts/rvm
rvm --autolibs=enable requirements ruby-2.0.0
