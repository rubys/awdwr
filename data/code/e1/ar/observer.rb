$: << File.dirname(__FILE__)

require "rubygems"
require "active_record"

require 'connect'

ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do 
  create_table :payments, :force => true do |t|
  end
end

class Order < ActiveRecord::Base
end

class Payment < ActiveRecord::Base
end

class Refund < ActiveRecord::Base
end

#START:observer
class OrderObserver < ActiveRecord::Observer
  def after_save(an_order)
    an_order.logger.info("Order #{an_order.id} created")
  end
end
#END:observer

OrderObserver.instance

#START:multi_observer
class AuditObserver < ActiveRecord::Observer

  observe Order, Payment, Refund

  def after_save(model)
    model.logger.info("[Audit] #{model.class.name} #{model.id} created")
  end
end
#END:multi_observer

AuditObserver.instance


o = Order.create
p = Payment.create

