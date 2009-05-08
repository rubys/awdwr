ActionController::Routing::Routes.draw do |map|
  map.connect 'store/checkout',
       :conditions => { :method => :get },
       :controller => "store",
       :action     => "display_checkout_form"

  map.connect 'store/checkout',
       :conditions => { :method => :post },
       :controller => "store",
       :action     => "save_checkout_form"
end
