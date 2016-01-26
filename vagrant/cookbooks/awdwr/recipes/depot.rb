#
# install nodejs, mysql, ruby 1.9.3 and nokogiri
# checkout awdwr, gorp, and rails to a git directory
# create and populate a /home/vagrant/bin directory
# add bin to path, create a 'work' alias
# create a logs directory
# set up depot_production msyql database
#

package "nodejs"
package "libmysqlclient-dev"
package "mysql-server"
package "ruby1.9.3"
package "ruby-nokogiri"
package "libpq-dev"
package "zlib1g-dev"
package "libgmp3-dev"

directory "/home/vagrant/git" do
  user "vagrant"
  group "vagrant"
end

git "/home/vagrant/git/awdwr" do
  repository 'git://github.com/rubys/awdwr.git'
  user "vagrant"
  group "vagrant"
end

git "/home/vagrant/git/gorp" do
  repository 'git://github.com/rubys/gorp.git'
  user "vagrant"
  group "vagrant"
end

git "/home/vagrant/git/rails" do
  repository 'git://github.com/rails/rails.git'
  user "vagrant"
  group "vagrant"
end

bash '/home/vagrant/bin' do
  user 'vagrant'
  group 'vagrant'
  cwd '/home/vagrant'
  environment 'HOME' => '/home/vagrant'
  code %{
    mkdir bin
    sed "s'/home/rubys'$HOME'" < ~/git/awdwr/testrails.yml > bin/testrails.yml
    cp /vagrant/bin/* bin
  }
  not_if {File.exist? '/home/vagrant/bin'}
end

bash 'add bin to path' do
  user 'vagrant'
  group 'vagrant'
  cwd '/home/vagrant'
  code %{
    echo >> .bash_profile
    echo 'PATH=$PATH:$HOME/bin' >> .bash_profile
    echo "alias work='source ~/bin/work'" >> .bash_profile
  }
  not_if 'grep HOME/bin /home/vagrant/.bash_profile'
end

directory "/home/vagrant/logs" do
  user "vagrant"
  group "vagrant"
end

ruby_block 'create mysql depot_production' do
  block do
    open('|mysql -u root','w') do |file|
      file.write "GRANT ALL PRIVILEGES ON depot_production.* TO " +
                 "'username'@'localhost' IDENTIFIED BY 'password';\n"
      file.write "CREATE DATABASE IF NOT EXISTS depot_production;\n"
    end
  end
end
