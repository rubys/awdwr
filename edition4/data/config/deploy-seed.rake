#
# Additional task to deploy seed data
#

namespace :deploy do
  desc "reload the database with seed data"
  task :seed do
    on roles(:app) do
      execute "cd #{current_path}; bin/rails db:seed RAILS_ENV=production"
    end
  end
end
