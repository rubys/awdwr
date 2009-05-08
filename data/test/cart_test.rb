#START:initial
require 'test_helper'

class CartTest < ActiveSupport::TestCase
  #START:fixtures
  fixtures :products
  #END:fixtures
  #END:initial
  #START:unique_products
  def test_add_unique_products
    cart = Cart.new
    rails_book = products(:rails_book)
    ruby_book  = products(:ruby_book)
    cart.add_product rails_book
    cart.add_product ruby_book
    assert_equal 2, cart.items.size
    assert_equal rails_book.price + ruby_book.price, cart.total_price
  end
  #END:unique_products
  
  #START:duplicate_product
  def test_add_duplicate_product
    cart = Cart.new
    rails_book = products(:rails_book)
    cart.add_product rails_book
    cart.add_product rails_book
    assert_equal 2*rails_book.price, cart.total_price
    assert_equal 1, cart.items.size
    assert_equal 2, cart.items[0].quantity
  end 
  #END:duplicate_product
#START:initial
end
#END:initial
