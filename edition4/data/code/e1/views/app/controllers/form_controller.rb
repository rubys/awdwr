class FormController < ApplicationController
  def index
    list
    render_action 'list'
  end

  def list
    @product_pages, @products = paginate :product, :per_page => 10
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(params[:product])
    if @product.save
      flash['notice'] = 'Product was successfully created.'
      redirect_to :action => 'list'
    else
      render_action 'new'
    end
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    @product = Product.find(params[:id])
    if @product.update_attributes(params[:product])
      flash['notice'] = 'Product was successfully updated.'
      redirect_to :action => 'show', :id => @product
    else
      render_action 'edit'
    end
  end

  def destroy
    Product.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
