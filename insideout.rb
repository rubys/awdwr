require 'gorp'
require 'fileutils'

$title = 'Rails from the Inside Out'
$autorestart = nil
$output = 'insideout'
$checker = 'checkinout'

USER = 'sa3ruby'
HOST = 'depot.intertwingly.net'

Dir.chdir $WORK

section 1.1, 'XML to Raw SQLite3' do
  overview <<-EOF
    Our store resells products, so lets start with a list of products provided
    by our supplier.  We are ultimately going to want to do things with
    these products, so lets load them into a database.
  EOF

  FileUtils::rm_rf 'depot'
  FileUtils::mkdir_p 'depot'
  Dir.chdir 'depot'

  desc 'Start with some XML, listing a number of products.'
  edit 'testdata.xml' do |data|
    data[/()/,1] = read('sqlite3/testdata.xml')
  end

  desc 'Test that loading the XML produces the right data in the database.'
  edit 'test_products.rb' do |data|
    data[/()/,1] = read('sqlite3/test_products.rb')
  end

  desc 'Run that test, watch it fail.'
  cmd 'ruby test_products.rb'

  desc 'Now write the code that loads the database from XML.'
  edit 'load_products.rb' do |data|
    data[/()/,1] = read('sqlite3/load_products1.rb')
  end

  desc 'Verify that the this code does what it is intended to do.'
  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'

  desc 'Try it a second time -- see a problem.'
  cmd 'ruby load_products.rb'

  desc 'Before proceeding, set up git.'
  cmd 'cat ' + File.expand_path("~#{ENV['USER']}/.gitconfig")

  desc 'Verify the configuration.'
  cmd 'git repo-config --get-regexp user.*'

  desc 'Initialize a repository for the code.'
  cmd 'git init'

  desc 'Add everything in the current directory.'
  cmd 'git add .'

  desc 'Commit the changes.'
  cmd 'git commit -m "load via raw SQLite3"'
end

section 1.2, 'Update Using Raw SQLite3' do
  overview <<-EOF
    At this point, we could simply just add a DROP TABLE IF EXISTS to the
    SQL, but that's a wee bit drastic.  Over time, we are going to want to
    add columns (e.g., quantity_on_hand), so lets match products in the
    database against the contents of the XML by their original ("base") id,
    and update existing rows if they are already present, adding new
    rows when they are not.
  EOF

  desc 'Conditionally CREATE table, match based on id, and UPDATE when found.'
  edit 'load_products.rb' do |data|
    data[/(.*)/m,1] = read('sqlite3/load_products2.rb')
  end

  desc 'Run the same test as before.'
  cmd 'ruby load_products.rb'

  desc 'Note a problem.  For now, simply delete the database and try again.'
  cmd 'rm products.db'
  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'

  desc 'Try again.'
  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'

  desc 'See what files have changed.'
  cmd 'git status'

  desc 'See what the changes were.'
  cmd 'git diff'

  desc 'Commit all of the changes.'
  cmd 'git commit -a -m "update via raw SQLite3"'
end

section 1.3, 'Update Using ActiveRecord' do
  overview <<-EOF
    Our code is SQLite3 specific (for deployment, we might prefer MySQL or
    Oracle or DB2...), and is starting to get crufty.  Let's see if
    ActiveRecord can simplify things.
  EOF

  desc 'establish_connection, Schema.define, find_by_base_id, save!'
  edit 'load_products.rb' do |data|
    data[/(.*)/m,1] = read('sqlite3/load_products3.rb')
  end

  desc 'Run the same test.'
  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'

  desc 'Commit changes.'
  cmd 'git status'
  cmd 'git commit -a -m "update using ActiveRecord"'

  desc 'View the log of changes made so far.'
  cmd 'git log'
end

section 2.1, 'Rack' do
  overview <<-EOF
    Now, lets get that data to display in the brower, using the simplest
    thing that could possibly work, namely Rack.
  EOF

  desc 'Tests: response OK, 3 products, and verify one title.'
  edit 'test_product_server.rb' do |data|
    data[/()/,1] = read('rack/test_product_server.rb')
  end

  desc 'Establish connection, use Builder, and send response.'
  edit 'product_server.rb' do |data|
    data[/()/,1] = read('rack/product_server.rb')
  end

  desc 'Test the server logic.'
  cmd 'ruby test_product_server.rb'

  desc 'Minimal rack configuration.'
  edit 'config.ru' do |data|
    data[/()/,1] = read('rack/config.ru')
  end

  restart_server

  desc 'See the output produced.'
  get "/products"

  desc 'See what file we changed.'
  cmd 'git status'

  desc 'Add in the new files.'
  cmd 'git add *server.rb config.ru'

  desc 'Commit the changes.'
  cmd 'git commit -m "rack server"'

  desc 'Make the test data viewable'
  cmd 'mkdir public'
  cmd 'git mv testdata.xml public'

  desc 'Update the rack configuration.'
  edit 'config.ru' do |data|
    data << "\n" + <<-EOF.unindent(6)
      map '/' do
        run Rack::File.new('public')
      end
    EOF
  end

  restart_server

  desc 'Get the test data.'
  get "/testdata.xml"

  desc 'Update the loader script with the new location.'
  edit 'load_products.rb' do |data|
    data[/()testdata.xml/,1] = 'public/'
  end

  desc 'Verify the changes.'
  cmd 'rm products.db'
  cmd 'ruby load_products.rb'
  cmd 'ruby test_products.rb'

  desc 'Commit the results.'
  cmd 'git commit -a -m "serve testdata"'
end

section 2.2, 'Capistrano' do
  overview <<-EOF
    We've got the program working on our machine, let's deploy it to our
    server machine which is running Passenger (a.k.a. mod_rails a.k.a.
    mod_rack) on Apache's http.  This takes a bit of planning the first time,
    but then Capistrano takes all of the guesswork
    and potential for errors out of the equation when it really matters.
    Note: this step can be safely skipped on first reading.
  EOF

  require 'net/ssh'
  Net::SSH.start(HOST, USER) do |ssh|
    ssh.exec! "rm -rf #{HOST}"
    ssh.exec! 'rm -rf ~/git/depot.git'
    ssh.exec! 'mkdir -p ~/git/depot.git'
    ssh.exec! 'cd ~/git/depot.git; git --bare init'
  end

  desc 'Create our Capistrano configuration'
  cmd 'capify .'

  desc 'Tailor it extensively'
  edit 'config/deploy.rb' do |data|
    data[/(.*)/m,1] = read('capistrano/deploy.rb')
    data[/(rubys)/,1] = USER
    data[/(depot.pragprog.com)/,1] = HOST
    data.gsub! /<gempath>/, '$HOME/.gems'
    data.gsub! /^# default/, 'default'
  end

  desc 'Commit to the repository.'
  cmd 'git status'
  cmd 'git add config Capfile'
  cmd 'git commit -m "capify"'

  desc 'Push the repository to the server.'
  cmd "git remote add origin ssh://#{USER}@#{HOST}/~/git/depot.git"
  cmd 'git push origin master'

  desc 'Allow Capistrano to set up the server.'
  cmd 'cap deploy:setup'

  desc 'Check that the server is ready for deployment.'
  cmd 'cap deploy:check'

  desc 'Do the deployment.'
  cmd 'cap deploy'

  desc 'See the results.'
  get "http://#{HOST}/products"
  get "http://#{HOST}/testdata.xml"
end

section 2.3, 'Whenever' do
  overview <<-EOF
    At this point, we are displaying a what amounts to be static data.
    Presumably the supplier will be making changes, so let's set things up
    so that everything is updated every morning, before we wake up.
  EOF

  desc 'Load from the web (yes, this is our server, work with me for now)'
  edit 'load_products.rb' do |data|
    data[/^()/,1] = "require 'net/http'\n"
    data[/('public\/testdata.xml')/,1] = 'URI.parse(ARGV.first)'
    data[/(File.new)/,1] = 'Net::HTTP.get'
    data[/(input.close\n)/,1] = ''
  end

  desc 'Verify that the change works'
  cmd 'rm products.db'
  cmd "ruby load_products.rb http://#{HOST}/testdata.xml"
  cmd 'ruby test_products.rb'

  desc 'Set up whenever'
  cmd 'wheneverize .'

  desc 'Add a command to run load_products daily at 4:15 am'
  edit 'config/schedule.rb' do |data|
    data << "\n" + <<-EOF.unindent(6)
      root = File.dirname(File.expand_path(__FILE__))

      every 1.day, :at => '4:15 am' do
        command "cd \#{root}; ruby load_products.rb http://#{HOST}/testdata.xml"
      end
    EOF
  end

  desc 'Visually inspect what the crontab entry looks like.'
  cmd 'whenever'

  edit 'config/deploy.rb' do |data|
    data << "\n" + <<-'EOF'.unindent(6)
      namespace :deploy do
        desc "Update the crontab file"
          task :update_crontab, :roles => :db do
          run "cd #{release_path} && whenever --update-crontab #{application}"
        end
      end

      after "deploy:symlink", "deploy:update_crontab"
    EOF
  end

  desc 'Commit the changes.'
  cmd 'git st'
  cmd 'git add config/schedule.rb'
  cmd 'git commit -a -m "whenever"'

  desc 'Push and deploy!'
  cmd 'git push'
  cmd 'cap deploy'
end

section 3.1, 'Rails' do
  overview <<-EOF
    Taking a step back, we have done something real.  It doesn't do much,
    but it didn't really take much code either.  But the problems are starting
    to accumulate: our application directory is getting cluttered, changes to
    schemas is a problem, we have code duplicated that establishes the
    connection, and we haven't even begun thinking about updates.
    Additionally, we have the database in the git repository and while that
    has proven to be convenient so far, that won't be such a hot idea once we
    deploy.  And synchronizing gems versions between the machines is a pain...
    Fred Brooks once recommended that we "plan to throw one away; you
    will, anyhow."  As you will see, we are not exactly going to be throwing
    anything away, but we will be in a very real sense starting over.
  EOF

  desc "First, let Rails do its thing..."
  cmd 'cd ..; rails depot'

  desc "Throw away the Rack bootstrap, it served us well."
  cmd 'git rm config.ru'

  desc "Define the product anew."
  cmd 'ruby script/generate scaffold product base_id:integer ' +
    'title:string description:text image_url:string price:decimal'

  desc 'Tailor the definition to taste'
  edit Dir['db/migrate/*create_products.rb'].first do |data|
    data[/:price()/,1] = ', :precision => 8, :scale => 2, :default => 0'
  end

  desc 'Out with the old db.'
  cmd 'git rm products.db'

  desc 'In with the new.'
  cmd 'rake db:migrate'

  desc 'Write unit tests (this time using ActiveRecord!)'
  edit 'test/unit/product_test.rb' do |data|
    data[/(.*)/m,1] = read('rails/product_test.rb')
  end

  desc 'Run the tests and watch them fail.'
  cmd 'rake test:units'

  desc 'Put the load logic in the model (url or file: getting fancy!)'
  edit 'app/models/product.rb' do |data|
    data[/(.*)/m,1] = read('rails/product.rb')
  end

  desc 'Run the tests and watch them pass.'
  cmd 'rake test:units'

  desc 'Function tests are already provided and they pass!'
  cmd 'rake test:functionals'

  desc 'remove old tests and server'
  cmd 'git rm test_*.rb product_server.rb'

  restart_server

  desc 'Load testdata.'
  cmd %(ruby script/runner 'Product.import("public/testdata.xml")')

  desc 'Explore.'
  get '/products'
  get '/products/1'
  get '/products/1/edit'
  get '/products/new'

  desc 'Update whenever to use runner'
  edit 'config/schedule.rb' do |data|
    data[/(command.*)/,1] = "runner 'Product.import(\"http://#{HOST}/testdata.xml\")'"
  end

  desc 'Tell Rails about the gem path'
  edit 'config/deploy.rb' do |data|
    data << "\n" + <<-'EOF'.unindent(6)
      load 'ext/rails-database-migrations.rb'

      set :gemhome, "/home/sa3ruby/.gemlocal"
      task :after_deploy do
        run "cp #{current_release}/config/environment.rb " +
            "#{current_release}/config/environment.rb-"
        run "echo ENV[\\'GEM_HOME\\']=\\'#{gemhome}\\' > " +
            "#{current_release}/config/environment.rb"
        run "echo ENV[\\'GEM_PATH\\']=\\'#{gemhome}\\' >> " +
            "#{current_release}/config/environment.rb"
        run "cat #{current_release}/config/environment.rb- >> " +
            "#{current_release}/config/environment.rb"
        run "rm #{current_release}/config/environment.rb-"
        deploy::cleanup
      end
    EOF
  end
  
  desc 'Commit.  Push.  Deploy.'
  cmd 'git st'
  cmd 'git add .'
  cmd 'git commit -m "convert to Rails!"'
  cmd 'git push'
  cmd 'cap deploy:migrations'
  cmd 'cap deploy'

  desc "See this live."
  get "http://#{HOST}/products"
end
