class CreateAuthorBook < ActiveRecord::Migration
  def self.up
    create_table :authors_books, :id => false do |t|
      t.integer :author_id, :null => false
      t.integer :book_id,   :null => false
    end
  end

  def self.down
    drop_table :authors_books
  end
end
