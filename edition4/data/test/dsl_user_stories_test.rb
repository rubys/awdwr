require 'test_helper'

class DslUserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products

  #START:daves_details
  DAVES_DETAILS = {
      :name     => "Dave Thomas",
      :address  => "123 The Street",
      :email    => "dave@example.com",
      :pay_type => "Check"
  }
  #END:daves_details

  MIKES_DETAILS = {
      :name     => "Mike Clark",
      :address  => "345 The Avenue",
      :email    => "mike@pragmaticstudio.com",
      :pay_type => "Credit card"
  }
    
  def setup
    LineItem.delete_all
    Order.delete_all
    @ruby_book = products(:ruby)
    @rails_book = products(:two)
  end 
  
  # A user goes to the store index page. They select a product,
  # adding it to their cart. They then check out, filling in
  # their details on the checkout form. When they submit,
  # an order is created in the database containing
  # their information, along with a single line item
  # corresponding to the product they added to their cart.
  
  #START:test_buying_a_product
  def test_buying_a_product
    dave = regular_user
    dave.get "/"
    dave.is_viewing "index"
    dave.buys_a @ruby_book
    dave.has_a_cart_containing @ruby_book
    dave.checks_out DAVES_DETAILS
    dave.is_viewing "index"
    check_for_order DAVES_DETAILS, @ruby_book
  end
  #END:test_buying_a_product

  #START:test_two_people_buying
  def test_two_people_buying
    dave = regular_user
        mike = regular_user
    dave.buys_a @ruby_book
        mike.buys_a @rails_book
    dave.has_a_cart_containing @ruby_book
    dave.checks_out DAVES_DETAILS
        mike.has_a_cart_containing @rails_book
    check_for_order DAVES_DETAILS, @ruby_book
        mike.checks_out MIKES_DETAILS
        check_for_order MIKES_DETAILS, @rails_book
  end
  #END:test_two_people_buying
  
  #START:regular_user
  def regular_user
    open_session do |user|
      def user.is_viewing(page)
        assert_response :success
        assert_template page
      end
    
      def user.buys_a(product)
        xml_http_request :post, '/line_items', :product_id => product.id
        assert_response :success 
      end
    
      def user.has_a_cart_containing(*products)
        cart = Cart.find(session[:cart_id])
        assert_equal products.size, cart.line_items.size
        cart.line_items.each do |item|
          assert products.include?(item.product)
        end
      end
    
      def user.checks_out(details)
        get "/orders/new"
        assert_response :success
        assert_template "new"

       post_via_redirect "/orders",
                          :order => { :name     => details[:name],
                                     :address  => details[:address],
                                     :email    => details[:email],
                                     :pay_type => details[:pay_type]
                                    }
        assert_response :success
        assert_template "index"
        cart = Cart.find(session[:cart_id])
        assert_equal 0, cart.line_items.size
      end
    end  
  end
  #END:regular_user   
  
  def check_for_order(details, *products)
    order = Order.find_by_name(details[:name])
    assert_not_nil order
    
    assert_equal details[:name],     order.name
    assert_equal details[:address],  order.address
    assert_equal details[:email],    order.email
    assert_equal details[:pay_type], order.pay_type
    
    assert_equal products.size, order.line_items.size
    for line_item in order.line_items
      assert products.include?(line_item.product)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal order.email,           mail[:to].value
    for line_item in order.line_items
      assert_operator mail.body.to_s, :include?, line_item.product.title
    end
  end
end
