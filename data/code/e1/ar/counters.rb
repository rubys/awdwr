$: << File.dirname(__FILE__)
require "connect"
require "logger"

#ActiveRecord::Base.logger = Logger.new(STDERR)

require "rubygems"
require "active_record"


ActiveRecord::Schema.define do
  #START:migration
  create_table :products, :force => true do |t|
    t.string :title
    t.text :description
    # ...
    t.integer :line_items_count, :default => 0
  end
  #END:migration
  
  create_table :line_items, :force => true do |t|
    t.integer :product_id
    t.integer :order_id
    t.integer :quantity
    t.decimal :unit_price, :precision => 8, :scale => 2
  end
  
end

class Product < ActiveRecord::Base
  has_many :line_items
end

#START:line_item
class LineItem < ActiveRecord::Base
  belongs_to :product, :counter_cache => true
end
#END:line_item

#START:count_issue
product = Product.create(:title => "Programming Ruby",
                         :description => " ... ")
line_item = LineItem.new
line_item.product = product
line_item.save
puts "In memory size = #{product.line_items.size}"             #=> 0
puts "Refreshed size = #{product.line_items(:refresh).size}"   #=> 1
#END:count_issue



LineItem.delete_all
Product.delete_all

#START:count_fix
product = Product.create(:title => "Programming Ruby", 
                         :description => " ... ")
product.line_items.create
puts "In memory size = #{product.line_items.size}"             #=> 1
puts "Refreshed size = #{product.line_items(:refresh).size}"   #=> 1
#END:count_fix



