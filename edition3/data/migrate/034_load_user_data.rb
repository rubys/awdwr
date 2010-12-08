require 'active_record/fixtures'

class LoadUserData < ActiveRecord::Migration
  def self.up
    down

    directory = File.join(File.dirname(__FILE__), 'dev_data')
    Fixtures.create_fixtures(directory, "users")
  end

  def self.down
    User.delete_all
  end
end
