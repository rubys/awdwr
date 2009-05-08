class CreateTableTickets < ActiveRecord::Migration
  def self.up
    create_table :tickets, :options => "auto_increment = 10000" do |t|
      t.text :description, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :tickets
  end
end
