# As a convenience for remote ("ssh") development, a server that
# serves a dual purpose: hosts the dashboard app, and reverse
# proxies all other requests to http://localhost:3000/

require_relative './dash-app.rb'

gem 'rack-reverse-proxy'
require 'rack/reverse_proxy'

set :bind, '0.0.0.0'
set :port, 9907

reverse_proxy = Rack::ReverseProxy.new do
  reverse_proxy '/', 'http://localhost:3000/'
end

get '/favicon.ico' do
  status 404
end

get %r{/.*} do
  reverse_proxy.call(env)
end

Sinatra::Application.run!
