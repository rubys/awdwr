# frozen_string_literal: true
# START:first_test
# START:second_test
require "test_helper"

class SupportMailboxTest < ActionMailbox::TestCase
# END:second_test
  # START_HIGHLIGHT
  test "we create a SupportRequest when we get a support email" do
    receive_inbound_email_from_mail(
      to: "support@example.com",
      from: "chris@somewhere.net",
      subject: "Need help",
      body: "I can't figure out how to check out!!"
    )

    support_request = SupportRequest.last
    assert_equal "chris@somewhere.net", support_request.email
    assert_equal "Need help", support_request.subject
    assert_equal "I can't figure out how to check out!!", support_request.body
    assert_nil support_request.order
  end
  # END_HIGHLIGHT

# END:first_test
# START:second_test

  # previous test

  # START_HIGHLIGHT
  test "we create a SupportRequest with the most recent order" do
    recent_order  = orders(:one)
    older_order   = orders(:another_one)
    non_customer  = orders(:other_customer)

    receive_inbound_email_from_mail(
      to: "support@example.com",
      from: recent_order.email,
      subject: "Need help",
      body: "I can't figure out how to check out!!"
    )

     support_request = SupportRequest.last
     assert_equal recent_order.email, support_request.email
     assert_equal "Need help", support_request.subject
     assert_equal "I can't figure out how to check out!!", support_request.body
     assert_equal recent_order, support_request.order
  end
  # END_HIGHLIGHT

# END:second_test


# START:second_test
# START:first_test
end
# END:first_test
# END:second_test
