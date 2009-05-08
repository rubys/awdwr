class AddColumnsToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :attn, :string, :limit => 100
    add_column :orders, :order_type,  :integer
    add_column :orders, :ship_class, :string, :null => false, :default => 'priority'
    add_column :orders, :amount, :decimal, :precision => 8, :scale => 2
    add_column :orders, :state, :string, :limit => 2
  end

  def self.down
    remove_column :orders, :attn
    remove_column :orders, :age
    remove_column :orders, :ship_class
    remove_column :orders, :amount
    remove_column :orders, :state
  end
end
