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

  open('|mysql -u root','w') do |file|
    file.puts "DROP DATABASE IF EXISTS depot_production;"
  end

  desc 'Create database'
  cmd "mysql --version"
  cmd "echo 'CREATE DATABASE depot_production DEFAULT CHARACTER SET utf8;' " +
    "| mysql -u root"

  system "rm -rf #{$HOME}/localhost"
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
# cmd 'cap deploy:migrations'
  cmd 'cap deploy:seed'

  desc 'Deploy'
  cmd 'cap deploy'
  system 'sed -i "s/localhost/depot.pragprog.com/" config/deploy.rb'
end
