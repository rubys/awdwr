require 'rubygems'
require 'gorp'

include Gorp::Commands

$title = 'Agile Web Development with Rails, Edition 4'
$autorestart = 'depot'
$output = 'deploydepot'
$checker = 'checkdeploy'

# what version of Rails are we running?
$rails_version = `#{Gorp.which_rails($rails)} -v 2>#{DEV_NULL}`.split(' ').last
if $rails_version =~ /^[23]/
  STDERR.puts 'This scenario is for Rails 4'
  Process.exit!
end

$HOME = ENV['HOME']
$HOME ||= "/home/#{ENV['USER']}" if File.exist? "/home/#{ENV['USER']}"

section 16.1, 'Capistrano' do
  Dir.chdir(File.join($WORK, 'depot'))

  overview <<-EOF
    Deploying our application locally using Capistrano
  EOF

  if ENV['USER'] == 'vagrant'
    desc 'Configure passenger'
    if not `which lsb_release`.empty? and `lsb_release -i`.include? 'Ubuntu'
      if `dpkg -s libapr1-dev 2>&1`.include? 'not installed'
        cmd 'sudo apt-get install -y build-essential zlib1g-dev ' +
          'libcurl4-openssl-dev apache2-prefork-dev libapr1-dev libaprutil1-dev'
      end
    end

    apache_needs_restarted = false

    begin
      save = {}
      ENV.keys.dup.each {|key| save[key]=ENV.delete(key) if key =~ /^BUNDLE_/}
      save['RUBYOPT'] = ENV.delete('RUBYOPT') if ENV['RUBYOPT']

      if `gem list passenger | grep passenger`.strip.empty?
        cmd 'gem install passenger --version 4.0.0.rc4'
        cmd 'yes | passenger-install-apache2-module'
      end

      if not File.exist? '/etc/apache2/conf.d/passenger'
        cmd 'passenger-install-apache2-module --snippet | ' +
          'sudo tee /etc/apache2/conf.d/passenger'

        apache_needs_restarted = true
      end
    ensure
      save.each {|key, value| ENV[key] = value}
    end

    if not File.exist? '/etc/apache2/sites-available/depot'
      edit 'tmp/site-depot' do
        self.all = <<-EOF.unindent(10)
          <VirtualHost *:80>
             ServerName depot.pragprog.com
             DocumentRoot #{$HOME}/deploy/depot/current/public/
             <Directory #{$HOME}/deploy/depot/current/public>
                AllowOverride all
                Options -MultiViews   
                Order allow,deny
                Allow from all
             </Directory>
          </VirtualHost>
        EOF
      end
      cmd 'sudo mv tmp/site-depot /etc/apache2/sites-available/depot'
      cmd 'sudo a2ensite depot'
      apache_needs_restarted = true
    end

    cmd 'sudo apachectl restart' if apache_needs_restarted

    if not File.exist? "#{$HOME}/.ssh/id_dsa.pub"
      desc 'enable ssh access to localhost'
      cmd "ssh-keygen -t dsa -N '' -f ~/.ssh/id_dsa"
      cmd "cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys"
    end
  end

  desc 'Create database'
  db_config = File.read('config/database.yml')
  if db_config.include? 'mysql'
    open('|mysql -u root','w') do |file|
      file.puts "DROP DATABASE IF EXISTS depot_production;"
    end

    cmd "mysql --version"
  elsif 
    system 'dropdb depot_production 2>/dev/null'
    cmd "psql --version"
  end

  rake "db:create RAILS_ENV=production"

  system "rm -rf #{$HOME}/work/depot"
  system "rm -rf #{$HOME}/git/depot.git"

  desc 'Create code repository'
  cmd "mkdir -p #{$HOME}/git/depot.git"
  Dir.chdir "#{$HOME}/git/depot.git" do
    cmd "git --bare init"
  end

  system 'git remote rm origin' if `git remote` =~ /^origin$/

  desc 'Initial code drop'
  cmd 'git add .'
  cmd 'git commit -m "prep for deploy"'
  bundle 'package'

  desc 'Push out updates'
  cmd 'git add Gemfile.lock vendor/cache'
  cmd 'git commit -q -m "bundle gems"'
  cmd 'git remote add origin ~/git/depot.git'
  cmd 'git push origin master'

  system 'sed -i "s/depot.pragprog.com/localhost/" config/deploy.rb'
  desc 'Initial capistrano setup'
  cmd 'cap deploy:setup'
  cmd 'cap deploy:check'
  cmd 'cap deploy:seed'

  desc 'Deploy'
  cmd 'cap deploy'
  system 'sed -i "s/localhost/depot.pragprog.com/" config/deploy.rb'
end
