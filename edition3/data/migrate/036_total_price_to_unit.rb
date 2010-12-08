class TotalPriceToUnit < ActiveRecord::Migration
  def self.up
    add_column :line_items, :unit_price, :decimal, :precision => 8, :scale => 2
    LineItem.update_all("unit_price = total_price / quantity / 100.0")
  end

  def self.down
    remove_column :line_items, :unit_price
  end
end
