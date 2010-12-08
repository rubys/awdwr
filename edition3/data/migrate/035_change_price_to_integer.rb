class ChangePriceToInteger < ActiveRecord::Migration
  def self.up
    LineItem.update_all("total_price = total_price * 100")
    change_column :line_items, :total_price, :integer
  end

  def self.down
    change_column :line_items, :total_price, :precision => 8, :scale => 2
    LineItem.update_all("total_price = total_price / 100.0")
  end
end
