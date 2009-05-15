class CreateDetails < ActiveRecord::Migration
  def self.up
    create_table :details do |t|
      t.integer :product_id
      t.string  :sku
      t.string  :manufacturer
    end
  end

  def self.down
    drop_table :details
  end
end
