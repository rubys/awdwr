require "./config/environment.rb"

ActionController::Base.session_store = nil
require "active_support/test_case"
rs = ActionController::Routing::Routes
app = ActionDispatch::Integration::Session.new(nil)

puts rs.routes
rs.recognize_path "/store"
rs.recognize_path "/store/add_to_cart/1"
rs.recognize_path "/store/add_to_cart/1.xml"
rs.generate :controller => :store
rs.generate :controller => :store, :id => 123
app.url_for :controller => :store, :action => :display, :id => 123
