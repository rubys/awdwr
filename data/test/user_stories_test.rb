require 'test_helper'

class UserStoriesTest < ActionController::IntegrationTest
  fixtures :products

  # A user goes to the index page. They select a product, adding it to their
  # cart, and check out, filling in their details on the checkout form. When
  # they submit, an order is created containing their information, along with a
  # single line item corresponding to the product they added to their cart.
  
  test "buying a product" do
    #START:setup
    LineItem.delete_all
    Order.delete_all
    ruby_book = products(:ruby_book)
    #END:setup

    #START:step1
    get "/store/index"
    assert_response :success
    assert_template "index"
    #END:step1
    
    #START:step2
    xml_http_request :put, "/store/add_to_cart", :id => ruby_book.id
    assert_response :success 
    
    cart = session[:cart]
    assert_equal 1, cart.items.size
    assert_equal ruby_book, cart.items[0].product
    #END:step2
    
    #START:step3
    post "/store/checkout"
    assert_response :success
    assert_template "checkout"
    #END:step3
    
    #START:step4
    post_via_redirect "/store/save_order",
                      :order => { :name     => "Dave Thomas",
                                 :address  => "123 The Street",
                                 :email    => "dave@pragprog.com",
                                 :pay_type => "check" }
    assert_response :success
    assert_template "index"
    assert_equal 0, session[:cart].items.size
    #END:step4
    
    #START:step5
    orders = Order.find(:all)
    assert_equal 1, orders.size
    order = orders[0]
    
    assert_equal "Dave Thomas",       order.name
    assert_equal "123 The Street",    order.address
    assert_equal "dave@pragprog.com", order.email
    assert_equal "check",             order.pay_type
    
    assert_equal 1, order.line_items.size
    line_item = order.line_items[0]
    assert_equal ruby_book, line_item.product
    #END:step5
  end
end
