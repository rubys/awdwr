$: << File.dirname(__FILE__)
require "connect"
require "logger"

#ActiveRecord::Base.logger = Logger.new(STDOUT)

require "rubygems"
require "active_record"

ActiveRecord::Schema.define do

  create_table :products, :force => true do |t|
    t.string   :title
    t.text     :description
    t.string   :image_url
    t.decimal  :price, :precision => 10, :scale => 2
    t.datetime :available_at
  end

  create_table :line_items, :force => true do |t|
    t.integer :product_id
    t.integer :order_id
    t.integer :quantity
    t.integer :unit_price, :precision => 8, :scale => 2
  end
end

#START:models
#START:product
class Product < ActiveRecord::Base
  has_many :line_items
end
#END:product

class LineItem < ActiveRecord::Base
  belongs_to :product
end
#END:models

LineItem.delete_all

p = Product.create(:title => "Programming Ruby", :available_at => Time.now)
l = LineItem.new
l.id = 2
l.product = p
l.save!

l = LineItem.new
l.product = p
l.save!

puts "\n\nSimple Belongs to"

#START:simple_belongs_to
item = LineItem.find(2)

# item.product is the associated Product object
puts "Current product is #{item.product.id}"
puts item.product.title

item.product = Product.new(:title          => "Rails for Java Developers",
                           :description    => "...",
                           :image_url      => "http://....jpg",
                           :price          => 34.95,
                           :available_at   => Time.now)
item.save!

puts "New product is #{item.product.id}"
puts item.product.title
#END:simple_belongs_to

puts "\n\nCreate belongs to"

item = LineItem.find(2)

# item.product is the associated Product object
puts "Current product is #{item.product.id}"
puts item.product.title

#START:create_belongs_to
item.create_product(:title          => "Rails Recipes",
                    :description    => "...",
                    :image_url      => "http://....jpg",
                    :price          => 32.95,
                    :available_at   => Time.now)
#END:create_belongs_to

puts "New product is #{item.product.id}"
puts item.product.title

puts "\n\nproduct belongs to"
#START:product_belongs_to
item = LineItem.find(2)

# item.product is the associated Product object
puts "Current product is #{item.product.id}"
puts item.product.title

item = LineItem.new()

item.create_product(:title          => "Advanced Rails", 
                    :description    => "...",
                    :image_url      => "http://....jpg",
                    :price          => 34.95,
                    :available_at   => Time.now)

puts "New product is #{item.product.id}"
puts item.product.title
#END:product_belongs_to
item.save!
p item.product(true)

puts "============="

prod = Product.find(item.product_id)
p prod.line_items.size
