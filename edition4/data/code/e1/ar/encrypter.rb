$: << File.dirname(__FILE__)
require "./config/environment.rb"

require "active_record"

ActiveRecord::Schema.define do
  
  #START:migration
  create_table :orders, :force => true do |t|
    t.integer :user_id
    t.string  :name
    t.string  :address
    t.string  :email
  end
  
  create_table :users, :force => :true do |t|
    t.string :name
  end
  #END:migration
end


#START:base
class ActiveRecord::Base
  def self.encrypt(*attr_names)
    encrypter = Encrypter.new(attr_names)
    
    before_save encrypter
    after_save  encrypter
    after_find  encrypter

    define_method(:after_find) { }
  end
end
#END:base

#START:encrypter  
class Encrypter

  # We're passed a list of attributes that should
  # be stored encrypted in the database
  def initialize(attrs_to_manage)
    @attrs_to_manage = attrs_to_manage
  end

  # Before saving or updating, encrypt the fields using the NSA and
  # DHS approved Shift Cipher
  def before_save(model)
    @attrs_to_manage.each do |field|
      model[field].tr!("a-z", "b-za")
    end
  end

  # After saving, decrypt them back
  def after_save(model)
    @attrs_to_manage.each do |field|
      model[field].tr!("b-za", "a-z")
    end
  end

  # Do the same after finding an existing record
  alias_method :after_find, :after_save
end
#END:encrypter

#START:order
class Order < ActiveRecord::Base
  encrypt(:name, :email)
end
#END:order

#START:driver
o = Order.new
o.name = "Dave Thomas"
o.address = "123 The Street"
o.email   = "dave@example.com"
o.save
puts o.name

o = Order.find(o.id)
puts o.name
#END:driver
