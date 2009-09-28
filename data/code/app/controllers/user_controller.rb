class UserController < ApplicationController
  def self.in_place_loader_for(object, attribute, options = {})
    define_method("get_#{object}_#{attribute}") do
      @item = object.to_s.camelize.constantize.find(params[:id])
      render :text => (@item.send(attribute).blank? ? "[No Name]" : @item.send(attribute))
    end
  end  
  in_place_edit_for :user, :username
  in_place_loader_for :user, :username
  in_place_edit_for :user, :favorite_language
  in_place_loader_for :user, :favorite_language
  include FavoriteLanguage
  before_filter :inject_id, 
      :only=>[:sortable_demo, :expando_demo, :drag_demo, 
              :inplace_demo, :inplace_before, :autocomplete_demo, 
              :autocomplete_before, :drag_before, :sortable_before,
              :expando_before, :drag_demo_effect]
              
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @search = ""
    @users = User.paginate :page => params[:page],
        :per_page => 10, :order=>order_from_params
  end
  
  def list_before
    list
  end
  
  def list_demo
    list
  end
  
  def refresh_list
    @users = User.paginate :page => params[:page],
        :per_page => 10, :order=>order_from_params
    render(:partial => 'users')
  end

  def show
    @user = User.find(params[:id])
  end
  
  def show_demo
    @user = User.find(params[:id])
  end

  def expando_before
    expando_demo
  end
  
  def expando_demo
    @user = User.find(params[:id])
    @accolades = @user.accolades
    render :layout=>'accolade'
  end
  
  def drag_before
    drag_demo
  end
  
  def drag_demo
    @user = User.find(params[:id])
    @completed_todos = @user.completed_todos
    @pending_todos = @user.pending_todos
  end
  
  def drag_demo_effect
    @user = User.find(params[:id])
    @completed_todos = @user.completed_todos
    @pending_todos = @user.pending_todos
  end

  def sortable_before
    sortable_demo
  end
  
  def sortable_demo
    @user = User.find(params[:id])
    @completed_todos = @user.completed_todos
    @pending_todos = @user.pending_todos
  end

  def sort_pending_todos
    params[:pending_todo_list].each_with_index do |pos, idx|
      t = Todo.find(pos.to_i)
      t.position = idx
      t.save!
    end
    @user = User.find(params[:id])
    @completed_todos = @user.completed_todos
    @pending_todos = @user.pending_todos
    render :update do |page|
      page.replace_html 'pending_todos', :partial => 'pending_todos'
      page.replace_html 'completed_todos', :partial => 'completed_todos'
      page.sortable "pending_todo_list", :url=>{:action=>:sort_pending_todos, :id=>@user}
    end
  end
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = 'User was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'show', :id => @user
    else
      render :action => 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def destroy_accolade
    a = Accolade.find(params[:id])
    a.destroy
    redirect_to :action => 'expando_demo', :id=>a.user
  end
  
  def add_accolade
    @user = User.find(params[:user][:id])
    @accolade = @user.accolades.build(params[:accolade])
    if @accolade.save
      flash[:notice] = 'Accolade added'
    else
      flash[:notice] = 'Accolade could not be added'
    end
    @accolades = @user.accolades
    if request.xhr?
      render :partial=>'accolades'
    else
      redirect_to :action=>'expando_demo', :id=>@user
    end
  end
  
  def autocomplete_demo
    @user = User.find(params[:id])
  end
  
  def autocomplete_before
    @user = User.find(params[:id])
    render :layout=>'user_no_js'
  end
  # START: autocomplete action
  def autocomplete_favorite_language
    re = Regexp.new("#{params[:user][:favorite_language]}", "i")
    @languages= LANGUAGES.find_all do |l|
      l.match re
    end
    render :layout=>false
  end
  # END: autocomplete action  
  def inplace_demo
    @user = User.find(params[:id])
  end
  
  def inplace_before
    @user = User.find(params[:id])
    render :layout=>'user_no_js'
  end
  
  def search_demo
    list
  end
  
  def search_before
    list
    render :layout=>'user_no_js'
  end
  
  def sort_before
    list
  end
  
  def sort_demo
    list
  end
  
  #START:codecite ajax without layout
  def search
    unless params[:search].blank?
      @users = User.paginate :page => params[:page],
        :per_page   => 10, 
        :order      => order_from_params,
        :conditions => User.conditions_by_like(params[:search])
      logger.info @users.size  
    else
      list
    end
    render :partial=>'search', :layout=>false
  end
  #END:codecite ajax without layout
  
  def sort
    search
  end
  
  # START: rjs 
  def todo_completed
    update_todo_completed_date Time.now
  end
  
  def todo_pending
    update_todo_completed_date nil
  end
  
  private

  def update_todo_completed_date(newval)
    @user = User.find(params[:id])
    @todo = @user.todos.find(params[:todo])
    @todo.completed = newval
    @todo.save!
    @completed_todos = @user.completed_todos
    @pending_todos = @user.pending_todos
    render :update do |page|
      page.replace_html 'pending_todos', :partial => 'pending_todos'
      page.replace_html 'completed_todos', :partial => 'completed_todos'
      page.sortable "pending_todo_list", 
          :url=>{:action=>:sort_pending_todos, :id=>@user}
    end
  end
  # END: rjs

  def inject_id
    redirect_to :id=>User.find_random.id unless params[:id]
  end
  
  def order_from_params
    if params[:form_sort] && params[:form_sort].size > 0
      params[:form_sort].downcase.split(",").map { |x| 
        x.tr(" ", "_")
      }.join(" ")
    else
      "username"
    end
  end
  
end
