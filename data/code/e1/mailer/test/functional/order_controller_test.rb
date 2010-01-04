require 'test_helper'

class OrderControllerTest < ActionController::TestCase

  fixtures :orders

  def setup
    @controller = OrderController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

#START:setup
    @emails     = ActionMailer::Base.deliveries
    @emails.clear
#END:setup
  end

  def test_confirm
    get(:confirm, :id => orders(:daves_order).id)
    assert_redirected_to(:action => :index)
    assert_equal(1, @emails.size)
    email = @emails.first
    assert_equal("Pragmatic Store Order Confirmation", email.subject)
    assert_equal("dave@example.com", email.to_addrs.join)
    assert_match(/Dear Dave Thomas/,  email.body)
  end
end
