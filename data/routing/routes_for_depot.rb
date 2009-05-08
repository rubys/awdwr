require 'activesupport'
require 'action_controller'
require 'action_controller/integration'
load "config/routes.rb"

ActionController::Routing.use_controllers! ["store", "admin", "coupon"]
rs = ActionController::Routing::Routes
app = ActionController::Integration::Session.new

puts rs.routes
rs.recognize_path "/store"
rs.recognize_path "/store/add_to_cart/1"
rs.recognize_path "/store/add_to_cart/1.xml"
rs.generate :controller => :store
rs.generate :controller => :store, :id => 123
rs.recognize_path "/coupon/show/1"
load "config/routes.rb"
rs.recognize_path "/coupon/show/1"
app.url_for :controller => :store, :action => :display, :id => 123
