require File.dirname(__FILE__) + '/../test_helper'

class RoutingTest < ActionController::TestCase
  #START:recognizes
  def test_method_specific_routes
    assert_recognizes({"controller" => "store", "action" => "display_checkout_form"},
                       :path => "/store/checkout", :method => :get)
    assert_recognizes({"controller" => "store", "action" => "save_checkout_form"},
                      :path => "/store/checkout", :method => :post)
  end
  #END:recognizes
end

