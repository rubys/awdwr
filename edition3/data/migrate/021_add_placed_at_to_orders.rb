class AddPlacedAtToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :placed_at, :datetime, :default => Time.now
  end

  def self.down
    remove_column :orders, :placed_at
  end
end
