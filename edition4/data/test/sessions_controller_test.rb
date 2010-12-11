#START:original
require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
#END:original

  fixtures :users
  
#START:original
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
#END:original
  
  #START:test_login
  test "login" do
    dave = users(:one)
    post :create, :name => dave.name, :password => 'secret'
    assert_redirected_to admin_url
    assert_equal dave.id, session[:user_id]
  end
  #END:test_login

  #START:test_bad_password
  test "bad password" do
    dave = users(:one)
    post :create, :name => dave.name, :password => 'wrong'
    assert_redirected_to login_url
  end
  #END:test_bad_password
#START:original
end
#END:original
