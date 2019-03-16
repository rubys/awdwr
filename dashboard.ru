require 'wunderbar/rack'
require 'rack/static'

require_relative 'dashboard'

use Rack::Static, urls: Dir['*.js', 'edition*'].map {|file| "/#{file}"}

app = Proc.new do |env|
  case env['PATH_INFO']
  when '/'
    _app.call(env)
  else
    [404, {'Content-Type' => 'text/plain'}, ['Not Found']]
  end
end

run app
