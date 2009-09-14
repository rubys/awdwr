$: << File.dirname(__FILE__)
require "connect"
require "logger"

#ActiveRecord::Base.logger = Logger.new(STDOUT)

require "rubygems"
require "active_record"


ActiveRecord::Schema.define do 
  # START:migration
  create_table :accounts, :force => true do |t|
    t.string  :number
    t.decimal :balance, :precision => 10, :scale => 2, :default => 0
  end
  # END:migration
end


#START:class_account
#START:transfer
class Account < ActiveRecord::Base
#END:class_account
  def self.transfer(from, to, amount)
    transaction(from, to) do
      from.withdraw(amount)
      to.deposit(amount)
    end
  end
#END:transfer
#START:class_account

  def withdraw(amount)
    adjust_balance_and_save(-amount)
  end

  def deposit(amount)
    adjust_balance_and_save(amount)
  end

  private

  def adjust_balance_and_save(amount)
    self.balance += amount
    save!
  end

  def validate    # validation is called by Active Record
    errors.add(:balance, "is negative") if balance < 0
  end
#START:transfer
end
#END:transfer
#END:class_account

#START:fixed
  def adjust_balance_and_save(amount)
    self.balance += amount
  end
#END:fixed

#START:setup
peter = Account.create(:balance => 100, :number => "12345")
paul  = Account.create(:balance => 200, :number => "54321")
#END:setup

case ARGV[0] || "1"

when "1"
  #START:xfer1
  Account.transaction do
    paul.deposit(10)
    peter.withdraw(10)
  end
  #END:xfer1

when "2"
  #START:xfer2
  Account.transaction do
    paul.deposit(350)
    peter.withdraw(350)
  end
  #END:xfer2

when "3"
  #START:xfer3
  begin
    Account.transaction do
      paul.deposit(350)
      peter.withdraw(350)
    end
  rescue
    puts "Transfer aborted"
  end
  
  puts "Paul has #{paul.balance}"
  puts "Peter has #{peter.balance}"
  #END:xfer3

when "4"
  #START:xfer4
  begin
    Account.transaction(peter, paul) do
      paul.deposit(350)
      peter.withdraw(350)
    end
  rescue
    puts "Transfer aborted"
  end
  
  puts "Paul has #{paul.balance}"
  puts "Peter has #{peter.balance}"
  #END:xfer4
  
when "5"
  #START:xfer5
  Account.transfer(peter, paul, 350) rescue  puts "Transfer aborted"
  
  puts "Paul has #{paul.balance}"
  puts "Peter has #{peter.balance}"
  #END:xfer5

end



