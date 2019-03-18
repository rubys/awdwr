#!/usr/bin/ruby
require 'etc'
require 'fileutils'

prereqs = {
  apachectl: 'apache2',
  curl: 'curl',
  git: 'git',
  mysql: 'libmysqlclient-dev mysql-server',
  nodejs: 'nodejs'
}

prereqs[:mysql].sub! '-server', '-client' if File.exist? '/.dockerenv'

# accept node as an alias for nodejs; not absolutely required on Mac OS/X
prereqs.delete :nodejs unless `which node`.empty?
prereqs.delete :nodejs if RUBY_PLATFORM.include? 'darwin'

# check prereqs
prereqs.keys.each do |cmd|
  next unless `which #{cmd}`.empty?
  if Process.uid == 0
    system "apt-get install -y #{prereqs[cmd]}"
  elsif %(awdwr vagrant ubuntu).include? Etc.getlogin
    system "sudo apt-get install -y #{prereqs[cmd]}"
  else
    STDERR.puts "Unable to find #{cmd}"
    exit -1
  end
end

unless RUBY_PLATFORM.include? 'darwin'
  unless %w(nodejs node).any? {|cmd| not `which #{cmd}`.empty?}
    STDERR.puts "Unable to find nodejs"
    exit -1
  end
end

# set up mysql
mysql_root = (File.exist?('/.dockerenv') ? '' : '-u root')
if ENV['MYSQL_ROOT_PASSWD']
  mysql_root += " -p#{ENV['MYSQL_ROOT_PASSWD']}"
elsif system("mysql -u root -proot < /dev/null 2>&0")
  mysql_root += ' -proot'
end
open("|mysql #{mysql_root}",'w') do |file|
  file.write "GRANT ALL PRIVILEGES ON depot_production.* TO " +
    "'username'@'localhost' IDENTIFIED BY 'password';"
end

# set up postgres
unless `which psql`.empty?
  open('|psql postgres','w') do |file|
    file.write "alter user username password 'password';"
  end
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
    repository.sub! '@github.com:', '://github.com/' unless ENV['USER']=='rubys'
    system "git clone #{repository}"
  end
end

if `which rbenv`.empty?
  rvm_path = File.expand_path(ENV['rvm_path'] || '~/.rvm')
  if not File.exist? rvm_path
    # download key
    unless `gpg --list-keys`.include? 'D39DC0E3'
      system 'gpg --keyserver hkp://keys.gnupg.net --recv-keys ' +
        '409B6B1796C275462A1703113804BB82D39DC0E3'
    end

    # install rvm
    system 'bash -c "curl -L https://get.rvm.io | bash -s stable"'
    exit -1 unless File.exist? rvm_path
    cmd = "source #{rvm_path}/scripts/rvm; rvm default system; " +
      "rvm --autolibs=enable requirements ruby-2.6.1"
    system 'bash -c ' + cmd.inspect
  end
end

if `which bundler`.empty?
  if ENV['rvm_version']
    system 'gem install bundler'
  else
    system 'sudo gem install bundler'
  end
end

FileUtils.mkdir_p File.expand_path('~/logs')
