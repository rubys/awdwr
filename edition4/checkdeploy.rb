require 'rubygems'
require 'gorp/test'

$rails_version = `#{Gorp.which_rails($rails)} -v 2>#{DEV_NULL}`.split(' ').last

class DepotTest < Gorp::TestCase

  input 'deploydepot'
  output 'checkdeploy'

  section 16.1, 'Capistrano' do
    assert_select '.stderr', /executing `deploy:setup'/
    assert_select '.stderr', /executing `deploy:check'/
    assert_select '.stdout', 
      "You appear to have all necessary dependencies installed"
    assert_select '.stderr', /executing `deploy:migrations'/
    assert_select '.stderr', /==  CreateUsers: migrated/
    assert_select '.stderr', /executing `assets:precompile'/
    assert_select '.stderr', /Writing.*public\/assets\/rails-[0-9a-f]+\.png/
    assert_select '.stderr', /executing "touch.*restart.txt"/
    assert_select '.stderr', :text => /^failed/, :count => 0

    # find deploy directory
    config = File.read('depot/config/deploy.rb')
    deploy_to  = config[/^set :deploy_to, "(.*)"/,1]
    deploy_to.sub! '#{user}', config[/^set :user, '(.*)'/,1]
    deploy_to.sub! '#{application}', config[/^set :application, '(.*)'/,1]
    assert File.exist? deploy_to

    # verify compressed css
    css = Dir["#{deploy_to}/current/public/assets/application*.css"]
    assert_equal 1, css.length
    asset = File.read(css.first)
    assert_match /\}\./, asset

    # verify compressed js
    js = Dir["#{deploy_to}/current/public/assets/application*.js"]
    assert_equal 1, js.length
    asset = File.read(js.first)
    assert_match /\}function/, asset
  end
end
