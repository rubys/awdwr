require 'rexml/document'
require 'sqlite3'

input  = File.new('products.xml')
output = SQLite3::Database.new('products.db')

unless output.execute('select name from sqlite_master').include? ["products"]
  output.execute_batch <<-SQL
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      base_id INTEGER,
      title varchar(255), 
      description text, 
      image_url varchar(255),
      price decimal(8,2) DEFAULT 0
    );
  SQL
end

REXML::Document.new(input).each_element('//product') do |product|
  title       = product.elements['title'].text
  description = product.elements['description'].text
  image_url   = product.elements['image-url'].text
  price       = product.elements['price'].text

  base_id     = product.elements['id'].text

  id = output.execute('SELECT id FROM products WHERE base_id=?', base_id)
  if id.empty?
    output.execute 'INSERT INTO products' +
      '(base_id, title, description, image_url, price)' +
      ' VALUES (?, ?, ?, ?, ?)', base_id, title, description, image_url, price
  else
    output.execute 'UPDATE products ' +
      'SET base_id=?, title=?, description=?, image_url=?, price=? WHERE id=?',
      base_id, title, description, image_url, price, id.first
  end
end

input.close
output.close
