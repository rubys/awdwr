$: << File.dirname(__FILE__)
require "logger"
require "rubygems"
require "activerecord"

require "vendor/plugins/acts_as_list/init"

require "connect"

#ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Base.connection.instance_eval do
  
  #START:migrations
  create_table :parents, :force => true do |t|
  end
  
  create_table :children, :force => true do |t|
    t.integer :parent_id
    t.string  :name
    t.integer :position
  end
  #END:migrations
end


#START:model
class Parent < ActiveRecord::Base
  has_many :children, :order => :position
end

class Child < ActiveRecord::Base
  belongs_to :parent
  acts_as_list  :scope => :parent
end
#END:model


#START:setup
parent = Parent.create
%w{ One Two Three Four}.each do |name|
  parent.children.create(:name => name)
end
parent.save
#END:setup

#START:display
def display_children(parent)
  puts parent.children(true).map {|child| child.name }.join(", ")
end
#END:display

#START:demo
display_children(parent)         #=> One, Two, Three, Four

puts parent.children[0].first?   #=> true

two = parent.children[1]
puts two.lower_item.name         #=> Three
puts two.higher_item.name        #=> One

parent.children[0].move_lower
display_children(parent)         #=> Two, One, Three, Four

parent.children[2].move_to_top
display_children(parent)         #=> Three, Two, One, Four

parent.children[2].destroy
display_children(parent)         #=> Three, Two, Four
#END:demo
