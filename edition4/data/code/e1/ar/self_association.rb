$: << File.dirname(__FILE__)
require "connect"
require "logger"

#ActiveRecord::Base.logger = Logger.new(STDERR)

require "rubygems"
require "active_record"

ActiveRecord::Schema.define do
  create_table :employees, :force => true do |t|
    t.string :name
    t.integer :manager_id
    t.integer :mentor_id
  end
end

#START:employee
class Employee < ActiveRecord::Base
  belongs_to :manager,
             :class_name  => "Employee",
             :foreign_key => "manager_id"

  belongs_to :mentor,
             :class_name  => "Employee", 
             :foreign_key => "mentor_id"
  
  has_many   :mentored_employees,
             :class_name  => "Employee",
             :foreign_key => "mentor_id"

  has_many   :managed_employees,
             :class_name  => "Employee",
             :foreign_key => "manager_id"
end
#END:employee

#START:load
Employee.delete_all

adam = Employee.create(:name => "Adam")
beth = Employee.create(:name => "Beth")

clem = Employee.new(:name => "Clem")
clem.manager = adam
clem.mentor  = beth
clem.save!

dawn = Employee.new(:name => "Dawn")
dawn.manager = adam
dawn.mentor  = clem
dawn.save!
#END:load

#START:try
p adam.managed_employees.map {|e| e.name}  # => [ "Clem", "Dawn" ]
p adam.mentored_employees                  # => []
p dawn.mentor.name                         # => "Clem"
#END:try


