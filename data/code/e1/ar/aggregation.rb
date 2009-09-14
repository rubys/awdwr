$: << File.dirname(__FILE__)
require "connect"
require "logger"
require "pp"

#ActiveRecord::Base.logger = Logger.new(STDOUT)

#require "rubygems"
#require_gem "active_record"

ActiveRecord::Schema.define do
  #START:migration
  create_table :customers, :force => true do |t|
    t.datetime :created_at
    t.decimal  :credit_limit, :precision => 10, :scale => 2, :default => 100
    t.string   :first_name
    t.string   :initials
    t.string   :last_name
    t.datetime :last_purchase
    t.integer  :purchase_count, :default => 0
  end
  #END:migration
end

#START:lastfive
class LastFive
  
  attr_reader :list

  # Takes a string containing "a,b,c" and 
  # stores [ 'a', 'b', 'c' ]
  def initialize(list_as_string)
    @list = list_as_string.split(/,/)
  end


  # Returns our contents as a 
  # comma delimited string
  def last_five
    @list.join(',')
  end
end
#END:lastfive

#START:purchase
class Purchase < ActiveRecord::Base
  composed_of :last_five
end
#END:purchase

Purchase.delete_all

#START:purchasedemo
Purchase.create(:last_five => LastFive.new("3,4,5"))

purchase = Purchase.find(:first)

puts purchase.last_five.list[1]     #=>  4
#END:purchasedemo


#START:name
class Name
  attr_reader :first, :initials, :last

  def initialize(first, initials, last)
    @first = first
    @initials = initials
    @last = last
  end

  def to_s
    [ @first, @initials, @last ].compact.join(" ")
  end
end
#END:name

#START:customer  
class Customer < ActiveRecord::Base

  composed_of :name,
              :class_name => "Name",
              :mapping => 
                 [ # database       ruby
                   %w[ first_name   first ],
                   %w[ initials     initials ],
                   %w[ last_name    last ] 
                 ]
end
#END:customer

Customer.delete_all

#START:namedemo
name = Name.new("Dwight", "D", "Eisenhower")

Customer.create(:credit_limit => 1000, :name => name)

customer = Customer.find(:first)
puts customer.name.first    #=> Dwight
puts customer.name.last     #=> Eisenhower
puts customer.name.to_s     #=> Dwight D Eisenhower
customer.name = Name.new("Harry", nil, "Truman")
customer.save
#END:namedemo

