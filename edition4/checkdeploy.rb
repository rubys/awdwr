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
  end
end
