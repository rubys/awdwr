$: << File.dirname(__FILE__)
require 'connect'

require 'rubygems'
require 'active_record'
require 'pp'

ActiveRecord::Schema.define do
  #START:migration
  create_table :purchases, :force => true do |t|
    t.string :name
    t.text   :last_five
  end
  #END:migration
end

#START:class
class Purchase < ActiveRecord::Base
  serialize :last_five
  # ...
end
#END:class

#START:save
purchase = Purchase.new
purchase.name = "Dave Thomas"
purchase.last_five = [ 'shoes', 'shirt', 'socks', 'ski mask', 'shorts' ]
purchase.save
#END:save

#START:read
purchase = Purchase.find_by_name("Dave Thomas")
pp purchase.last_five
pp purchase.last_five[3]
# END:read
