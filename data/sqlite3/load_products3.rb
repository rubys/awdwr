require 'rexml/document'
require 'rubygems'
require 'active_record'

input  = File.new('products.xml')

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'products.db')

class Product < ActiveRecord::Base
  unless table_exists?
    ActiveRecord::Schema.define do
      create_table :products do |t|
        t.integer :base_id
        t.string  :title
        t.text    :description
        t.string  :image_url
        t.decimal :price, :precision=>8, :scale=>2, :default=>0.0
      end
    end
  end
end

REXML::Document.new(input).each_element('//product') do |xproduct|
  base_id  = xproduct.elements['id'].text

  product = Product.find_by_base_id(base_id) || Product.new 

  product.base_id     = base_id
  product.title       = xproduct.elements['title'].text
  product.description = xproduct.elements['description'].text
  product.image_url   = xproduct.elements['image-url'].text
  product.price       = xproduct.elements['price'].text

  product.save!
end

input.close
ActiveRecord::Base.remove_connection
