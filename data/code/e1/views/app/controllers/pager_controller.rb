if Rails::VERSION::MAJOR < 3
#START:gem
Rails::Initializer.run do |config|
  config.gem 'will_paginate', :version => '~> 2.3.11',
    :source => 'http://gemcutter.org'
end
#END:gem
end
    
class PagerController < ApplicationController

  def populate
    User.delete_all

    User.transaction do
      ["Chris Pine",
       "Chad Fowler",
       "Dave Thomas",
       "Andy Hunt",
       "Adam Keys",
       "Maik Schmidt",
       "Mike Mason",
       "Greg Wilson",
       "Jeffrey Fredrick",
       "James Gray",
       "Daniel Berger",
       "Eric Hodel",
       "Brian Marick",
       "Mike Gunderloy",
       "Ryan Davis",
       "Scott Davis",
       "David Heinemeier Hansson",
       "Scott Barron",
       "Marcel Molina",
       "Brian McCallister",
       "Mike Clark",
       "Esther Derby",
       "Johanna Rothman",
       "Juliet Thomas",
       "Thomas Fuchs"].each {|name| User.create(:name => name)}

      763.times do |i|
        User.create(:name => "ZZUser #{"%03d" % i}")
      end
    end
  end

  #START:user_list
  def user_list
    @users = User.paginate :page => params[:page], :order => 'name'
  end
  #END:user_list

end
