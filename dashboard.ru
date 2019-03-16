require 'wunderbar/rack'
require 'rack/static'

require_relative 'dashboard'

puts urls: Dir['edition*'].
  map {|file| ["/#{file}", "/#{file}/index.html"]}.to_h
use Rack::Static, urls: Dir['edition*'].
  map {|file| ["/#{file}", "/#{file}/index.html"]}.to_h
puts urls: Dir['*.js', 'edition*'].map {|file| "/#{file}"}
use Rack::Static, urls: Dir['*.js', 'edition*'].map {|file| "/#{file}"}

static = nil
app = Proc.new do |env|
  case env['PATH_INFO']
  when '/'
    _app.call(env)
  else
    [404, {'Content-Type' => 'text/plain'}, ['Not Found']]
  end
end

run app
