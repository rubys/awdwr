# be sure to change these
set :user, 'rubys'
set :domain, 'depot.pragprog.com'
set :application, 'depot'

# adjust if you are using RVM, remove if you are not
set :rvm_type, :system
set :rvm_ruby_string, 'ruby-2.3.1'

# file paths
set :repo_url, "#{fetch(:user)}@#{fetch(:domain)}:git/#{fetch(:application)}.git" 
set :deploy_to, "/home/#{fetch(:user)}/deploy/#{fetch(:application)}" 

# distribute your applications across servers (the instructions below put them
# all on the same server, defined above as 'domain', adjust as necessary)
role :app, fetch(:domain)
role :web, fetch(:domain)
role :db, fetch(:domain), :primary => true

# you might need to set this if you aren't seeing password prompts
# default_run_options[:pty] = true

# As Capistrano executes in a non-interactive mode and therefore doesn't cause
# any of your shell profile scripts to be run, the following might be needed
# if (for example) you have locally installed gems or applications.  Note:
# this needs to contain the full values for the variables set, not simply
# the deltas.
# default_environment['PATH']='<your paths>:/usr/local/bin:/usr/bin:/bin'
# default_environment['GEM_PATH']='<your paths>:/usr/lib/ruby/gems/1.8'

# miscellaneous options
set :deploy_via, :remote_cache
set :scm, 'git'
set :branch, 'master'
set :scm_verbose, true
set :use_sudo, false
set :normalize_asset_timestamps, false
set :rails_env, :production

namespace :deploy do
  desc "reload the database with seed data"
  task :seed do
    on roles(:app) do
      execute "cd #{current_path}; " +
        "rails db:seed RAILS_ENV=#{fetch(:rails_env)}"
    end
  end
end
