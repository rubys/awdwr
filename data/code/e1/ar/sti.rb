$: << File.dirname(__FILE__)
require "connect"
require "logger"

ActiveRecord::Base.logger = Logger.new(STDERR)

ActiveRecord::Schema.define do

  # START:migration
  create_table :people, :force => true do |t|
    t.string :type

    # common attributes
    t.string :name
    t.string :email

    # attributes for type=Customer
    t.decimal :balance, :precision => 10, :scale => 2

    # attributes for type=Employee
    t.integer :reports_to
    t.integer :dept

    # attributes for type=Manager
    # -- none -- 
  end
  #END:migration
  
end

#START:define
class Person < ActiveRecord::Base
end

class Customer < Person
end

class Employee < Person
  belongs_to :boss, :class_name => "Manager", :foreign_key => :reports_to
end

class Manager < Employee
end
#END:define

#START:demo
Customer.create(:name => 'John Doe',    :email => "john@doe.com",    
                :balance => 78.29)
                
wilma = Manager.create(:name  => 'Wilma Flint', :email => "wilma@here.com",  
                       :dept => 23)
               
Customer.create(:name => 'Bert Public', :email => "b@public.net",    
                :balance => 12.45)
                
barney = Employee.new(:name => 'Barney Rub',  :email => "barney@here.com", 
                      :dept => 23)
barney.boss = wilma
barney.save!

manager = Person.find_by_name("Wilma Flint")
puts manager.class    #=> Manager
puts manager.email    #=> wilma@here.com
puts manager.dept     #=> 23

customer = Person.find_by_name("Bert Public")
puts customer.class    #=> Customer
puts customer.email    #=> b@public.net
puts customer.balance  #=> 12.45
#END:demo

b = Person.find_by_name("Barney Rub")
p b.boss
