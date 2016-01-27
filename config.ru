# quick and dirty hack to run CGI as a Sinatra view
#
# Rationale: as an alternative to SUEXEC options on Mac/OSX, enable
# running the dashboard as a Phusion Passenger application.

require 'wunderbar/sinatra'

$HOME = ENV['HOME']

DASHBOARD = File.read(File.expand_path('../dashboard.rb', __FILE__)).untaint

get '/' do
  eval DASHBOARD.sub(/^_json.*/m, '').sub('_.post?', 'false')
end

post '/' do
  pass unless request.accept.find {|x| x.to_s == 'application/json'}
  eval DASHBOARD.sub(/^_html.*\n_json/m, '_json').sub(/^__END__.*/m, '')
end

post '/' do
  eval DASHBOARD.sub(/^_json.*/m, '').sub('_.post?', 'true')
end

get %r{^/AWDwR4/(.*)/$} do |path|
  send_file "edition4/#{path}/index.html"
end

get %r{^/AWDwR4/(.*)} do |path|
  send_file "edition4/#{path}"
end

get %r{^/([-\w.]+.js)} do |path|
  send_file "vagrant/www/#{path}"
end

run Sinatra::Application
