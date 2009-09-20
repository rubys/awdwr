require 'test_helper'

class RoutingTest < ActionController::TestCase

  # the following is needed for Rails 2.2.2, but entirely unnecessary for
  # 2.3.2
  tests StoreController
  def setup
    load "config/routes_with_conditions.rb"
  end

  #START:recognizes
  def test_method_specific_routes
    assert_recognizes({"controller" => "store", "action" => "display_checkout_form"},
                       :path => "/store/checkout", :method => :get)
    assert_recognizes({"controller" => "store", "action" => "save_checkout_form"},
                      :path => "/store/checkout", :method => :post)
  end
  #END:recognizes
end

