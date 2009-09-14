$: << File.dirname(__FILE__)
require "connect"
require "logger"
require "rubygems"
require "active_record"

require "vendor/plugins/acts_as_tree/lib/active_record/acts/tree.rb"
require "vendor/plugins/acts_as_tree/init"

#ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do

  #START:migrations
  create_table :categories, :force => true do |t|
    t.string  :name
    t.integer :parent_id
  end
  #END:migrations
end




#START:model
class Category < ActiveRecord::Base
  acts_as_tree  :order => "name"
end
#END:model


#START:setup
root        = Category.create(:name => "Books")
fiction     = root.children.create(:name => "Fiction")
non_fiction = root.children.create(:name => "Non Fiction")

non_fiction.children.create(:name => "Computers")
non_fiction.children.create(:name => "Science")
non_fiction.children.create(:name => "Art History")

fiction.children.create(:name => "Mystery")
fiction.children.create(:name => "Romance")
fiction.children.create(:name => "Science Fiction")
#END:setup

def display_children(order)
  puts order.children.map {|child| child.name }.join(", ")
end

#START:demo
display_children(root)             # Fiction, Non Fiction

sub_category = root.children.first
puts sub_category.children.size    #=> 3
display_children(sub_category)     #=> Mystery, Romance, Science Fiction

non_fiction = root.children.find(:first, :conditions => "name = 'Non Fiction'")

display_children(non_fiction)      #=> Art History, Computers, Science
puts non_fiction.parent.name       #=> Books
#END:demo
