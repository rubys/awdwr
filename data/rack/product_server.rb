require 'rubygems'
require 'rack'
require 'builder'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'products.db')

class Product < ActiveRecord::Base
end

class ProductServer
  def call(env)
    x = Builder::XmlMarkup.new :indent=>2

    x.html do
      x.head do
        x.title 'Pragmatic Bookshelf'
      end
      x.body do
        x.h1 'Pragmatic Bookshelf'

        Product.all.each do |product|
          x.h2 product.title
          x << "      #{product.description}\n"
          x.p product.price
        end
      end
    end

    response = Rack::Response.new
    response['Content-Type'] = 'text/html'
    response.write x.target!
    response.finish
  end
end
