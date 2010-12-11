$: << File.dirname(__FILE__)
require "connect"
require "logger"
require "pp"

#ActiveRecord::Base.logger = Logger.new(STDERR)

require "rubygems"
require "active_record"

class LineItem < ActiveRecord::Base
end

LineItem.delete_all

LineItem.create(:quantity => 1, :product_id => 27, :order_id => 13, :unit_price => 29.95)
LineItem.create(:quantity => 2, :unit_price => 29.95)
LineItem.create(:quantity => 1, :unit_price => 44.95)

result = LineItem.find(:first)
p result.quantity
p result.unit_price

result = LineItem.find_by_sql("select quantity, quantity*unit_price " +
                              "from line_items")
pp result[0].attributes

result = LineItem.find_by_sql("select quantity, 
                                      quantity*unit_price as total_price " +
                              "from line_items")
pp result[0].attributes

p result[0].total_price
sales_tax = 0.07
p result[0].total_price * sales_tax

class LineItem < ActiveRecord::Base
  def total_price
    Float(read_attribute("total_price"))
  end

  CUBITS_TO_INCHES = 2.54

  def quantity
    read_attribute("quantity") * CUBITS_TO_INCHES
  end

  def quantity=(inches)
    write_attribute("quantity", Float(inches) / CUBITS_TO_INCHES)
  end
end

p result[0].quantity

result[0].quantity = 500
p result[0].save

