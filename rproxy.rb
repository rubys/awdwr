# As a convenience for remote ("ssh") development, a server that
# serves a dual purpose: hosts the dashboard app, and reverse
# proxies all other requests to http://localhost:3000/

require 'wunderbar/asset'
Wunderbar::Asset.path = 'ASSET'

require_relative './dash-app.rb'

gem 'rack-reverse-proxy'
require 'rack/reverse_proxy'

set :bind, '0.0.0.0'
set :port, 9907
set :persistent_timeout, 1

reverse_proxy = Rack::ReverseProxy.new do
  reverse_proxy_options preserve_host: false

  reverse_proxy '/', 'http://localhost:3000/'
end

get '/favicon.ico' do
  status 404
end

get '/*' do
  reverse_proxy.call(env.merge("HTTP_HOST" => "localhost:3000"))
end

post '/*' do
  reverse_proxy.call(env.merge("HTTP_HOST" => "localhost:3000"))
end

put '/*' do
  reverse_proxy.call(env.merge("HTTP_HOST" => "localhost:3000"))
end

delete '/*' do
  reverse_proxy.call(env.merge("HTTP_HOST" => "localhost:3000"))
end

Sinatra::Application.run!
