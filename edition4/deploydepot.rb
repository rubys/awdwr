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
