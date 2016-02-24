# quick and dirty hack to run CGI as a Sinatra view
#
# Rationale: as an alternative to SUEXEC options on Mac/OSX, enable
# running the dashboard as a Phusion Passenger application.

require 'wunderbar/sinatra'
require 'yaml'

$HOME = ENV['HOME'].dup.untaint

ENV.keys.each do |var|
  if var =~ /^rvm_|PASSENGER_|_ENV$/
    ENV.delete var
  end
end

DASHBOARD = File.read(File.expand_path('../dashboard.rb', __FILE__)).untaint
config = YAML.load_file(File.expand_path('../dashboard.yml', __FILE__))
logdir = File.expand_path(config['log']).untaint

get '/' do
  # FileUtils.touch File.expand_path('../tmp/restart.txt', __FILE__).untaint
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

get '/logs' do
  _html do
    _h2 "Logs"
    logs = Dir["#{logdir}/*"].map(&:untaint)
    
    _table do
      _tr do
        _th 'Updated'
        _th 'Size'
        _th 'Name'
      end

      logs.sort_by {|name| File.mtime(name)}.reverse.each do |fullname|
        name = File.basename(fullname)
        _tr do
          _td File.mtime(fullname).to_s
          _td File.size(fullname), align: 'right'
          _td {_a name, href: "logs/#{name}"}
        end
      end
    end
  end
end

get %r{^/logs/(\w[-\w]+\.\w+)$} do |log|
  content_type "text/plain"
  send_file "#{logdir}/#{log.untaint}"
end

get '/env' do
  # FileUtils.touch File.expand_path('../tmp/restart.txt', __FILE__).untaint

  _html do
    _h2 "Environment variables"
    _table do
      ENV.sort.each do |name, value|
        _tr do
          _td name
          _td value
        end
      end
    end

    _h2 "Request environment"
    _table do
      env.sort.each do |name, value|
        _tr do
          _td name
          _td value
        end
      end
    end
  end
end

run Sinatra::Application
