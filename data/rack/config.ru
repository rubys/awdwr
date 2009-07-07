require 'product_server'

use Rack::ShowExceptions

map '/products' do
  run ProductServer.new
end

map '/' do
  run Rack::File.new('public')
end
