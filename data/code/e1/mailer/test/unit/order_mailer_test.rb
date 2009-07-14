require 'test_helper'

class OrderMailerTest < ActionMailer::TestCase
  def setup
    @order = Order.new(:name => 'Dave Thomas', :email => 'dave@example.com')
    @expected.from    = 'orders@example.com'
    @expected.to      = 'dave@example.com'
  end

  test "confirm" do
    start = Time.now
    mailing = OrderMailer.create_confirm(@order)

    @expected.subject = 'Pragmatic Store Order Confirmation'
    @expected.body    = read_fixture('confirm')
    @expected.date    = mailing.date

    assert_operator mailing.date, :>=, start-1
    assert_equal @expected.encoded, mailing.encoded
  end

  test "sent" do
    start = Time.now
    mailing = OrderMailer.create_sent(@order)

    @expected.subject = 'Pragmatic Order Shipped'
    @expected.body    = read_fixture('sent')
    @expected.date    = mailing.date

    assert_operator mailing.date, :>=, start-1
    assert_equal @expected.encoded, mailing.encoded
  end

end
