$: << File.dirname(__FILE__)
require "connect"
require "logger"

ActiveRecord::Base.logger = Logger.new(STDERR)

# START:define
require "rubygems"
require "active_record"
require "pp"

@params = {}
def params
  @params
end

# START:def_pay_scopes
class Order < ActiveRecord::Base
  named_scope :check, :conditions => {:pay_type => 'check'}
  named_scope :cc,    :conditions => {:pay_type => 'cc'}
  named_scope :po,    :conditions => {:pay_type => 'po'}
end
#END:def_pay_scopes

# START:def_ranges
class Order < ActiveRecord::Base
  named_scope :recent, :conditions => ['created_at > ?', 1.week.ago]
  named_scope :since, lambda { |range| 
    { :conditions => ['created_at > ?', range] }
  }
end
# START:def_ranges

class LineItem < ActiveRecord::Base
end

class Product < ActiveRecord::Base
end

#START:find_first
# return an arbitrary order
order = Order.find(:first)

# return an order for Dave
order = Order.find(:first, :conditions => "name = 'Dave Thomas'")

# return the latest order for Dave
order = Order.find(:first,
                   :conditions => "name = 'Dave Thomas'", 
                   :order      => "id DESC")
#END:find_first

#START:find_by_sql1
orders = LineItem.find_by_sql("select line_items.* from line_items, orders " +
                              " where order_id = orders.id                 " +
                              "   and orders.name = 'Dave Thomas'          ")
#END:find_by_sql1


#START:find_by_sql2
orders = Order.find_by_sql("select name, pay_type from orders")

first = orders[0]
p first.attributes
p first.attribute_names
p first.attribute_present?("address")
#END:find_by_sql2


#START:pay_scopes
p Order.all
p Order.check(:order => "created_on desc").first
p Order.po.recent.count
p Order.check.find_by_name('Dave Thomas')
#END:pay_scopes

#START:ranges
p Order.po.recent(:order => :created_at)
p Order.po.since(1.week.ago)
#END:ranges

LineItem.delete_all
Product.delete_all
p = Product.create(:title => "Programming Ruby", :price => 49.95)
LineItem.create(:quantity => 2, :product_id => p.id, :order_id => first)

#START:find_by_sql3
items = LineItem.find_by_sql("select *,                                  " +
                             "  products.price as unit_price,            " +
                             "  quantity*products.price as total_price,  " +
                             "  products.title as title                  " +
                             " from line_items, products                 " +
                             " where line_items.product_id = products.id ")
li = items[0]
puts "#{li.title}: #{li.quantity}x#{li.unit_price} => #{li.total_price}"
#END:find_by_sql3

#START:count
c1 = Order.count
c2 = Order.count(:conditions => ["name = ?", "Dave Thomas"])
c3 = LineItem.count_by_sql("select count(*)                        " +
                           "  from line_items, orders              " +
                           " where line_items.order_id = orders.id " +
                           "   and orders.name = 'Dave Thomas'     ")
puts "Dave has #{c3} line items in #{c2} orders (#{c1} orders in all)"
#END:count

#START:dynamic1
order  = Order.find_by_name("Dave Thomas")
orders = Order.find_all_by_name("Dave Thomas")
orders = Order.find_all_by_email(params['email'])
#END:dynamic1

o = LineItem.find(:all,
                  :conditions => "pr.title = 'Programming Ruby'",
                  :joins => "inner join products as pr on line_items.product_id = pr.id")
p o.size

LineItem.delete_all

res = Order.update_all("pay_type = 'wibble'")
p res

res = Order.delete_all(["pay_type = ?", "wibble"])
p res
