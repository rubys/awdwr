require 'bundler/capistrano'

# be sure to change these
set :user, 'rubys'
set :domain, 'depot.pragprog.com'
set :application, 'depot'

# adjust if you are using RVM, remove if you are not
set :rvm_type, :user
set :rvm_ruby_string, '2.0.0'
require 'rvm/capistrano'

# file paths
set :repository,  "#{user}@#{domain}:git/#{application}.git" 
set :deploy_to, "/home/#{user}/deploy/#{application}" 

# distribute your applications across servers (the instructions below put them
# all on the same server, defined above as 'domain', adjust as necessary)
role :app, domain
role :web, domain
role :db, domain, :primary => true

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
  desc "cause Passenger to initiate a restart"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt" 
  end

  desc "reload the database with seed data"
  task :seed do
    deploy.migrations
    run "cd #{current_path}; rake db:seed RAILS_ENV=#{rails_env}"
  end
end

after 'deploy:update_code', 'assets:precompile'

namespace :assets do
  task :precompile, :roles => :app do
    run "mkdir -p #{shared_path}/tmp/cache && " +
      "ln -nfs #{shared_path}/tmp/cache #{release_path}/tmp/cache"
    run "mkdir -p #{shared_path}/assets && " +
      "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
    run "cd #{release_path} && RAILS_ENV=#{rails_env} RAILS_GROUPS=assets " +
      "#{rake} assets:precompile --trace"
  end
end
