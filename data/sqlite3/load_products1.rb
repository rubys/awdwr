require 'rexml/document'
require 'sqlite3'

input  = File.new('products.xml')
output = SQLite3::Database.new('products.db')

output.execute_batch <<SQL
  CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    title varchar(255), 
    description text, 
    image_url varchar(255),
    price decimal(8,2) DEFAULT 0
  );
SQL

REXML::Document.new(input).each_element('//product') do |product|
  output.execute 'INSERT INTO products(title,description,image_url,price)' +
    ' VALUES (?, ?, ?, ?)',
    product.elements['title'].text,
    product.elements['description'].text,
    product.elements['image-url'].text,
    product.elements['price'].text
end

input.close
output.close
