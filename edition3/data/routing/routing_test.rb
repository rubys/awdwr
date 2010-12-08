require 'test_helper'
require './config/routes.rb'

class RoutingTest < ActionController::TestCase

  #START:recognizes
  def test_recognizes
    if ActionController::Routing.respond_to? :use_controllers!
      ActionController::Routing.use_controllers! ["store"]
    end
    load "./config/routes.rb"

    # Check the default index action gets generated
    assert_recognizes({"controller" => "store", "action" => "index"}, "/store")
    
    # Check routing to an action
    assert_recognizes({"controller" => "store", "action" => "list"}, 
                      "/store/list")
    
    # And routing with a parameter
    assert_recognizes({ "controller" => "store", 
                        "action" => "add_to_cart", 
                       "id" => "1" },
                      "/store/add_to_cart/1")

    # And routing with a parameter
    assert_recognizes({ "controller" => "store", 
                        "action" => "add_to_cart", 
                        "id" => "1",
                        "name" => "dave" }, 
                      "/store/add_to_cart/1",
                      { "name" => "dave" } ) # like having ?name=dave after the URL

    # Make it a post request
    assert_recognizes({ "controller" => "store", 
                        "action" => "add_to_cart", 
                        "id" => "1" }, 
                      { :path => "/store/add_to_cart/1", :method => :post })
  end
  #END:recognizes
  
  #START:generates
  def test_generates
    if ActionController::Routing.respond_to? :use_controllers!
      ActionController::Routing.use_controllers! ["store"]
    end
    load "./config/routes.rb"

    assert_generates("/store", :controller => "store", :action => "index")
    assert_generates("/store/list", :controller => "store", :action => "list")
    assert_generates("/store/add_to_cart/1", 
                     { :controller => "store", :action => "add_to_cart", 
                       :id => "1", :name => "dave" },
                     {}, { :name => "dave"})
  end
  #END:generates
  
  #START:routing
  def test_routing
    if ActionController::Routing.respond_to? :use_controllers!
      ActionController::Routing.use_controllers! ["store"]
    end
    load "./config/routes.rb"

    assert_routing("/store", :controller => "store", :action => "index")
    assert_routing("/store/list", :controller => "store", :action => "list")
    assert_routing("/store/add_to_cart/1", 
                   :controller => "store", :action => "add_to_cart", :id => "1")
  end
  #END:routing
  
  def test_alternate_routing
    if ActionController::Routing.respond_to? :use_controllers!
      ActionController::Routing.use_controllers! ["store"]
    end
    load "./config/routes.rb"

    assert_generates("/store", :controller => "store")
    
    with_routing do |set|
      set.draw do |map|
        map.connect "shop/:action/:id", :controller => "store"
      end
      
      assert_generates("/shop", :controller => "store")
      assert_recognizes({:controller => "store", :action => "index"}, "/shop")
    end
    
    assert_generates("/store", :controller => "store")
  end    
    
end
