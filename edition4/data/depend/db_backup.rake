namespace :db do

  desc "Backup the production database"
  task :backup => :environment do
    backup_dir  = ENV['DIR'] || File.join(Rails.root, 'db', 'backup')

    source = File.join(Rails.root, 'db', "production.db")
    dest   = File.join(backup_dir, "production.backup")

    makedirs backup_dir, :verbose => true
    sh "sqlite3 #{source} .dump > #{dest}"
  end

end
