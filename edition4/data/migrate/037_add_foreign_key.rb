require 'migration_helpers'

class AddForeignKey < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    foreign_key :line_items, :product_id, :products
    foreign_key :line_items, :order_id,   :orders
  end

  def self.down
  end
end
