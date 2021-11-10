# quick and dirty hack to run CGI as a Sinatra view
#
# Rationale: as an alternative to SUEXEC options on Mac/OSX, enable
# running the dashboard as a Phusion Passenger application.

require_relative './dash-app.rb'

get '/' do
  call env.merge('PATH_INFO' => '/dashboard')
end

post '/' do
  call env.merge('PATH_INFO' => '/dashboard')
end

run Sinatra::Application
