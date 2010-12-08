class CreateTableTickets < ActiveRecord::Migration
  def self.up
    create_table :tickets, :primary_key => :number do |t|
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :tickets
  end
end
