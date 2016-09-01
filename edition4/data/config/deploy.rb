# be sure to change these values
user = 'rubys'
domain = 'depot.pragprog.com'

# adjust if you are using RVM, remove if you are not
set :rvm_type, :system
set :rvm_ruby_string, 'ruby-2.3.1'

# file paths
set :application, 'depot'
set :repo_url, "#{user}@#{domain}:git/#{fetch(:application)}.git" 
set :deploy_to, "/home/#{user}/deploy/#{fetch(:application)}" 

# distribute your applications across servers (the instructions below put them
# all on the same server, defined above as 'domain', adjust as necessary)
role :app, domain
role :web, domain
role :db, domain

# you might need to set this if you aren't seeing password prompts
# or are seeing errors like 'no tty present and no askpass program specified'
#
# set :pty true

# As Capistrano executes in a non-interactive mode and therefore doesn't cause
# any of your shell profile scripts to be run, the following might be needed
# if (for example) you have locally installed gems or applications.  Note:
# this needs to contain the full values for the variables set, not simply
# the deltas.
#
# set :default_environment, {
#   'PATH' => '<your paths>:/usr/local/bin:/usr/bin:/bin',
#   'GEM_PATH' => '<your paths>:/usr/lib/ruby/gems/1.8'
# }
#
# See https://rvm.io/deployment/capistrano#environment for more info.

#
# Additional task to deploy seed data
#

namespace :deploy do
  desc "reload the database with seed data"
  task :seed do
    on roles(:app) do
      execute "cd #{current_path}; rails db:seed RAILS_ENV=production"
    end
  end
end
