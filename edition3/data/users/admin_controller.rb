class AdminController < ApplicationController

  # just display the form and wait for user to
  # enter a name and password
  #START:login
  def login
    if request.post?
      user = User.authenticate(params[:name], params[:password])
      if user
        session[:user_id] = user.id
        redirect_to(:action => "index")
      else
        flash.now[:notice] = "Invalid user/password combination"
      end
    end
  end
  #END:login

  #START:logout
  def logout
    session[:user_id] = nil
    flash[:notice] = "Logged out"
    redirect_to(:action => "login")
  end
  #END:logout

  #START:index
  def index
    @total_orders = Order.count
  end
  #END:index
end
