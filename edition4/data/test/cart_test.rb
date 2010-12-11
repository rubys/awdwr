#START:initial
require 'test_helper'

class CartTest < ActiveSupport::TestCase
  #END:initial
  #START:unique_products
  test "add unique products" do
    cart = Cart.create
    book_one = products(:one)
    book_two  = products(:two)
    cart.add_product(book_one.id).save!
    cart.add_product(book_two.id).save!
    assert_equal 2, cart.line_items.size
    assert_equal book_one.price + book_two.price, cart.total_price
  end
  #END:unique_products
  
  #START:duplicate_product
  test "add_duplicate_product" do
    cart = Cart.create
    ruby_book = products(:ruby)
    cart.add_product(ruby_book.id).save!
    cart.add_product(ruby_book.id).save!
    assert_equal 2*book_one.price, cart.total_price
    assert_equal 1, cart.line_items.size
    assert_equal 2, cart.line_items[0].quantity
  end 
  #END:duplicate_product
#START:initial
end
#END:initial
