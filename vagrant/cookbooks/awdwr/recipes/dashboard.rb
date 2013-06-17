#
# install apache2
# install and configure suexec
# allow .htaccess overrides
# configure CGI
# enable file extensions to be omitted (MultiViewsMatch)
# set servername
# change owner of web directory to vagrant user and group
# install wunderbar gem
# install cgi wrapper for dashboard
# copy dashboard configuration file (yaml)
# install jquery
# Add a symbolic link to the logs, and order the logs by descending date
# restart apache2 server
# report on location of dashboard in Chef log and welcome message
#
 
package "apache2"
package "apache2-suexec"

bash 'enable suexec' do
  code 'a2enmod suexec'
  not_if {File.exist? '/etc/apache2/mods-enabled/suexec.load'}
end

ruby_block 'update site' do
  block do
    default = '/etc/apache2/sites-available/default'
    original = File.read(default)
    content = original.dup

    unless File.exist? "#{default}.bak"
      File.open("#{default}.bak", 'w') {|file| file.write original}
    end

    unless content.include? 'SuexecUserGroup'
      content.sub! "\n\n", "\n\tSuexecUserGroup vagrant vagrant\n\n"
    end

    content.sub!(%r{<Directory /var/www/>.*?\n\s*</Directory>}m) do |var_www|
      var_www.sub! /^\s*AllowOverride\s.*/ do |line|
        line.sub 'None', 'All'
      end

      var_www.sub! /^\s*Options\s.*/ do |line|
        line += ' +ExecCGI' unless line.include? 'ExecCGI'
        line
      end

      unless var_www.include? 'AddHandler cgi-script'
        var_www[%r{^()\s*</Directory>}, 1] = "\t\tAddHandler cgi-script .cgi\n"
      end

      unless var_www.include? 'MultiViewsMatch Any'
        var_www[%r{^()\s*</Directory>}, 1] = "\t\tMultiViewsMatch Any\n"
      end

      var_www
    end

    unless content == original
      File.open(default, 'w') {|file| file.write content}
    end
  end
end

file '/etc/apache2/conf.d/servername' do
  content "ServerName #{`hostname`}"
end

file '/etc/apache2/conf.d/log' do
  content "AddType text/plain .log"
end

directory '/var/www' do
  user 'vagrant'
  group 'vagrant'
end

gem_package "wunderbar" do
  gem_binary "/usr/bin/gem"
end

bash '/var/www/dashboard.cgi' do
  user 'vagrant'
  group 'vagrant'
  code 'ruby /home/vagrant/git/awdwr/dashboard.rb --install=/var/www'
  not_if {File.exist? '/var/www/dashboard.cgi'}
end

bash '/var/www/dashboard.yml' do
  user 'vagrant'
  group 'vagrant'
  cwd '/var/www'
  environment 'HOME' => '/home/vagrant'
  code %{
    sed "s'/home/rubys'$HOME'" < ~/git/awdwr/dashboard.yml > dashboard.yml
  }
  not_if {File.exist? '/var/www/dashboard.yml'}
end

bash '/var/www/jquery.min.js' do
  user 'vagrant'
  group 'vagrant'
  code %{
    cp /vagrant/www/* /var/www
  }
  not_if {File.exist? '/var/www/jquery.min.js'}
end

bash '/var/www/logs' do
  user 'vagrant'
  group 'vagrant'
  code %{
    ln -s /home/vagrant/logs /var/www/logs
  }
  not_if {File.exist? '/var/www/logs'}
end

file '/home/vagrant/logs/.htaccess' do
  user 'vagrant'
  group 'vagrant'
  content "IndexOptions +FancyIndexing\nIndexOrderDefault Descending Date\n"
end

bash '/var/www/AWDwR4' do
  user 'vagrant'
  group 'vagrant'
  code %{
    ln -s /home/vagrant/git/awdwr/edition4 /var/www/AWDwR4
  }
  not_if {File.exist? '/var/www/AWDwR4'}
end

service "apache2" do 
  action :restart
end

ruby_block 'welcome' do
  ip=%{/sbin/ifconfig eth1|grep inet|head -1|sed 's/\:/ /'|awk '{print \$3}'}

  block do
    profile = '/home/vagrant/.bash_profile'
    if not File.read(profile).include? ip
      open(profile, 'a') do |file|
        file.puts "\nip=$(#{ip})"
        file.write <<-'EOF'.gsub(/^ {10}/, '')
          if [[ "${TERM:-dumb}" != "dumb" ]]; then
            echo
            echo "Depot Dashboard is available at http://$ip/dashboard"

            PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
          fi
        EOF
      end

      Chef::ShellOut.new("chown vagrant:vagrant #{profile}").run_command
    end

    Chef::Log.info "Depot Dashboard is available at http://" + `#{ip}`.chomp +
      "/dashboard"
  end
end
