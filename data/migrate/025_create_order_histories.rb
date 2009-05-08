class CreateOrderHistories < ActiveRecord::Migration
  def self.up
    create_table :order_histories do |t|
      t.integer :order_id,   :null => false
      t.text :notes,      :text
  
      t.timestamps
    end
  end

  def self.down
    drop_table :order_histories
  end
end
