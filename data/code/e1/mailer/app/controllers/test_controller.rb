#START:sent
#START:create
class TestController < ApplicationController
#END:sent
  def create_order
    order = Order.find_by_name("Dave Thomas")
    email = OrderMailer.create_confirm(order)
    render(:text => "<pre>" + email.encoded + "</pre>")
  end
#END:create

#START:sent
  def ship_order
    order = Order.find_by_name("Dave Thomas")
    email = OrderMailer.create_sent(order)
    email.set_content_type("text/html")
    OrderMailer.deliver(email)
    render(:text => "Thank you...")
  end
#END:sent

#START:survey
  def survey
    order = Order.find_by_name("Dave Thomas")
    email = OrderMailer.deliver_survey(order)
    render(:text => "E-Mail sent")
  end
#END:survey

#START:ship_with_images
  def ship_with_images
    order = Order.find_by_name("Dave Thomas")
    email = OrderMailer.deliver_ship_with_images(order)
    render(:text => "E-Mail sent")
  end
#END:ship_with_images

#START:sent
#START:create
end
#END:create
#END:sent
