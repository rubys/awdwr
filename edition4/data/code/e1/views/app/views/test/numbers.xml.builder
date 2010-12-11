controller.headers["Content-Type"] = "text/plain"

xml.dl do
  show(xml, "human_size(123_456)")
  show(xml, "number_to_currency(123.45)")
  show(xml, %{number_to_currency(234.56, :unit => "CAN$", :precision => 0)})
  show(xml, "number_to_percentage(66.66666)")
  show(xml, "number_to_percentage(66.66666, :precision => 1)")
  show(xml, "number_to_phone(2125551212)")
  show(xml, %{number_to_phone(2125551212, :area_code => true, :delimiter => " ")})
  show(xml, "number_with_delimiter(12345678)")
  show(xml, %{number_with_delimiter(12345678, delimiter = "_")})
  show(xml, "number_with_precision(50.0/3)")
  show(xml, "number_with_precision(50.0/3, 1)")
end

