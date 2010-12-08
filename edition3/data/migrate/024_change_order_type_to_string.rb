class ChangeOrderTypeToString < ActiveRecord::Migration
  def self.up
    change_column :orders, :order_type, :string
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
