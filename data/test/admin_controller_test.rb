#START:original
require 'test_helper'

class AdminControllerTest < ActionController::TestCase
#END:original

  fixtures :users
  
#START:original
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
#END:original
  
  if false
    #START:index
    test "index" do
      get :index 
      assert_response :success 
    end
    #END:index
  end

  #START:index_without_user
  test "index without user" do
    get :index
    assert_redirected_to :action => "login"
    assert_equal "Please log in", flash[:notice]
  end
  #END:index_without_user

  #START:index_with_user
  test "index with user" do
    get :index, {}, { :user_id => users(:dave).id }
    assert_response :success
    assert_template "index"
  end
  #END:index_with_user
 
  #START:test_login
  test "login" do
    dave = users(:dave)
    post :login, :name => dave.name, :password => 'secret'
    assert_redirected_to :action => "index"
    assert_equal dave.id, session[:user_id]
  end
  #END:test_login

  #START:test_bad_password
  test "bad password" do
    dave = users(:dave)
    post :login, :name => dave.name, :password => 'wrong'
    assert_template "login"
  end
  #END:test_bad_password
#START:original
end
#END:original
