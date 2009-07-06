require 'product_server'

use Rack::ShowExceptions
# use Rack::Reloader

map "/" do
  run ProductServer.new
end

map "/favicon.ico" do
  run lambda {|env| Rack::Response.new('not found', 404).finish}
end
