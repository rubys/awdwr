require 'gorp'
require 'fileutils'

$title = 'Rails from the Inside Out'
$autorestart = nil
$output = 'insideout'
$checker = 'checkinout'

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
end

section 1.3, 'Update Using ActiveRecord' do
  edit 'load_products.rb' do |data|
    data[/(.*)/m,1] = read('sqlite3/load_products3.rb')
  end

  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'
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
  get "/"
  get "/favicon.ico"
end
