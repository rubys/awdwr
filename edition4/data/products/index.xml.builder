xml.div(:class => "productlist") do

  xml.timestamp(Time.now)
  
  @products.each do |product|
    xml.product do
      xml.productname(product.title)
      xml.price(product.price, :currency => "USD")
    end
  end
end
