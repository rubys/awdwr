require 'test_helper'

class OrderControllerTest < ActionController::TestCase
  def test_confirm
    get(:confirm, :id => orders(:daves_order).id)
    assert_redirected_to(:action => :index)
    assert_equal(1, ActionMailer::Base.deliveries.size)
    email = ActionMailer::Base.deliveries.first
    assert_equal("Pragmatic Store Order Confirmation", email.subject)
    assert_equal("dave@example.com", email.to[0])
    assert_match(/Dear Dave Thomas/,  email.body)
  end
end
