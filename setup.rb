#!/usr/bin/ruby

# notes:
#  * copy/setup .gitconfig, .ssh, bin/testrails*
#  * apt-get install ruby1.9.3
#  * gem install xmpp4r ruby-dbus
#  * apt-get install apache2 curl git libmysqlclient-dev mysql-server nodejs
#  * gem install nokogiri wunderbar

# check prereqs
require 'rubygems'
require 'xmpp4r'
%w(apache2ctl curl git mysql).each do |cmd| 
  next if cmd == 'apache2ctl' and not RUBY_PLATFORM.include? 'linux'
  next if system "which #{cmd} > /dev/null"
  STDERR.puts "Unable to find #{cmd}"
  exit -1
end
unless %w(nodejs node).any? {|cmd| system "which #{cmd}"}
  STDERR.puts "Unable to find nodejs"
  exit -1
end

# set up mysql
open('|mysql -u root','w') do | file|
  file.write "GRANT ALL PRIVILEGES ON depot_production.* TO " +
    "'username'@'localhost' IDENTIFIED BY 'password';"
end

# fetch code
repositories = %w(
  git@github.com:rubys/awdwr.git
  git@github.com:rubys/gorp.git
  git://github.com/rails/rails.git
)
require 'fileutils'
git_path = File.expand_path('~/git')
FileUtils.mkdir_p git_path
Dir.chdir git_path do
  repositories.each do |repository|
    next if File.exist? File.basename(repository, '.git')
    system "git clone #{repository}"
  end
end

# install rvm
require 'yaml'
rvm_path = File.expand_path(ENV['rvm_path'] || '~/.rvm')
if not File.exist? rvm_path
  system 'bash -c "curl -L https://get.rvm.io | bash -s stable"'
  exit -1 unless File.exist? rvm_path
  cmd = "source #{rvm_path}/scripts/rvm; rvm requirements"
  system 'bash -c ' + cmd.inspect
  exit 0
end
