require 'gorp'
require 'fileutils'

$title = 'Rails from the Inside Out'
$autorestart = nil
$output = 'insideout'
$checker = 'checkinout'

USER = 'sa3ruby'
HOST = 'depot.intertwingly.net'

Dir.chdir $WORK

section 1.1, 'XML to Raw SQLite3' do
  FileUtils::rm_rf 'depot'
  FileUtils::mkdir_p 'depot'
  Dir.chdir 'depot'

  edit 'products.xml' do |data|
    data[/()/,1] = read('sqlite3/products.xml')
  end

  edit 'test_products.rb' do |data|
    data[/()/,1] = read('sqlite3/test_products.rb')
  end

  edit 'load_products.rb' do |data|
    data[/()/,1] = read('sqlite3/load_products1.rb')
  end

  cmd 'ruby test_products.rb'
  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'
  cmd 'ruby load_products.rb'

  cmd 'cat ' + File.expand_path("~#{ENV['USER']}/.gitconfig")
  cmd 'git repo-config --get-regexp user.*'
  cmd 'git init'
  cmd 'git add .'
  cmd 'git commit -m "load via raw SQLite3"'
end

section 1.2, 'Update Using Raw SQLite3' do
  edit 'load_products.rb' do |data|
    data[/(.*)/m,1] = read('sqlite3/load_products2.rb')
  end

  cmd 'ruby load_products.rb'
  cmd 'rm products.db'
  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'
  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'

  cmd 'git status'
  cmd 'git diff'
  cmd 'git commit -a -m "update via raw SQLite3"'
end

section 1.3, 'Update Using ActiveRecord' do
  edit 'load_products.rb' do |data|
    data[/(.*)/m,1] = read('sqlite3/load_products3.rb')
  end

  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'

  cmd 'git status'
  cmd 'git commit -a -m "update using ActiveRecord"'
  cmd 'git log'
end

section 2.1, 'Rack' do
  edit 'test_product_server.rb' do |data|
    data[/()/,1] = read('rack/test_product_server.rb')
  end

  edit 'product_server.rb' do |data|
    data[/()/,1] = read('rack/product_server.rb')
  end

  cmd 'ruby test_product_server.rb'

  edit 'config.ru' do |data|
    data[/()/,1] = read('rack/config.ru')
  end

  restart_server
  get "/products"

  cmd 'git status'
  cmd 'git add *server.rb config.ru'
  cmd 'git commit -m "rack server"'
end

section 3.1, 'Capistrano' do
  require 'net/ssh'
  Net::SSH.start(HOST, USER) do |ssh|
    ssh.exec! 'rm -rf ~/git/depot.git'
    ssh.exec! 'mkdir -p ~/git/depot.git'
    ssh.exec! 'cd ~/git/depot.git; git --bare init'
  end
  cmd 'capify .'

  cmd 'git status'
  cmd 'git add config Capfile'
  cmd 'git commit -m "capify"'

  cmd "git remote add origin ssh://#{USER}@#{HOST}/~/git/depot.git"
  cmd 'git push origin master'

  edit 'config/deploy.rb' do |data|
    data[/(.*)/m,1] = read('capistrano/deploy.rb')
    data[/(rubys)/,1] = USER
    data[/(depot.pragprog.com)/,1] = HOST
  end

  cmd 'cap deploy:setup'
  cmd 'cap deploy:check'
  cmd 'cap deploy'

  get "http://#{HOST}/products"
end
