require 'active_support/all'
require 'action_view'
include ActionView::Helpers::NumberHelper
number_to_currency(123.45)
number_to_currency(234.56, :unit => "CAN$", :precision => 0)
number_to_human_size(123_456)
number_to_percentage(66.66666)
number_to_percentage(66.66666, :precision => 1)
number_to_phone(2125551212)
number_to_phone(2125551212, :area_code => true, :delimiter => " ")
number_with_delimiter(12345678)
number_with_delimiter(12345678, :delimiter => "_")
number_with_precision(50.0/3, :precision => 2)
