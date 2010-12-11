class ChangePriceToInteger < ActiveRecord::Migration
  def self.up
    Product.update_all("price = price * 100")
    change_column :products, :price, :integer
  end

  def self.down
    change_column :products, :price, :precision => 8, :scale => 2
    Product.update_all("price = price / 100.0")
  end
end
