require 'test_helper'

class OrderMailerTest < ActionMailer::TestCase
  def setup
    @order = Order.new(:name => 'Dave Thomas', :email => 'dave@example.com')
    @expected.from    = 'orders@example.com'
    @expected.to      = 'dave@example.com'
  end

  test "confirm" do
    @expected.subject = 'Pragmatic Store Order Confirmation'
    @expected.body    = read_fixture('confirm')
    @expected.date    = Time.now

    assert_equal @expected.encoded, OrderMailer.create_confirm(@order).encoded
  end

  test "sent" do
    @expected.subject = 'Pragmatic Order Shipped'
    @expected.body    = read_fixture('sent')
    @expected.date    = Time.now

    assert_equal @expected.encoded, OrderMailer.create_sent(@order).encoded
  end

end
