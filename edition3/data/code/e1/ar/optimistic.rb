$: << File.dirname(__FILE__)
require "connect"

require "rubygems"
require "active_record"

ActiveRecord::Schema.define do
  # START:migration
  create_table :counters, :force => true do |t|
    t.integer :count
    t.integer :lock_version, :default => 0
  end
  # END:migration
end


#START:optimistic
class Counter < ActiveRecord::Base
end

Counter.delete_all
Counter.create(:count => 0)

count1 = Counter.find(:first)
count2 = Counter.find(:first)

count1.count += 3 
count1.save
     
count2.count += 4 
count2.save
#END:optimistic
