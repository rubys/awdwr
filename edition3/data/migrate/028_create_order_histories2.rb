class CreateOrderHistories2 < ActiveRecord::Migration

  #START_HIGHLIGHT
  class Order < ActiveRecord::Base; end
  class OrderHistory < ActiveRecord::Base; end
  #END_HIGHLIGHT

  def self.up
    create_table :order_histories do |t|
      t.integer :order_id, :null => false
      t.text :notes
  
      t.timestamps
    end
  
    order = Order.find :first
    OrderHistory.create(:order_id => order, :notes => "test")
  end
  
  def self.down
    drop_table :order_histories
  end
end
