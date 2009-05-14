$: << File.dirname(__FILE__)
require "connect"
require "logger"

#ActiveRecord::Base.logger = Logger.new(STDOUT)

require "rubygems"
require "activerecord"

ActiveRecord::Schema.define do
  
  create_table :invoices, :force => true do |t|
    t.integer :order_id
  end

  create_table :orders, :force => true do |t|
    t.string   :name
    t.string   :email
    t.text     :address
    t.string   :pay_type
    t.datetime :shipped_at
  end

end

#START:models
class Order < ActiveRecord::Base
  has_one :invoice
end

class Invoice < ActiveRecord::Base
  belongs_to :order
end
#END:models

Order.create(:name => "Dave", :email => "dave@xxx",
             :address => "123 Main St", :pay_type => "credit",
             :shipped_at => Time.now)



order = Order.find(1)

p order.invoice

invoice = Invoice.new
if invoice.save
  order.invoice = invoice
else
  fail invoice.errors.to_s
end

p order.invoice

o = Order.new
p o.id
invoice.order = o
p o.id
invoice.save
p o.id
