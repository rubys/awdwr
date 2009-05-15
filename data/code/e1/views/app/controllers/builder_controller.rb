class BuilderController < ApplicationController
  
  def new
    @product = Product.new
  end
  
  def new_with_helper
    new
  end
  
  def save
    @product = Product.new(params[:product])
    if @product.save
      redirect_to :action => :index
    else
      render :action => :new
    end
  end
  
  def index
    render :inline => "You have <%= pluralize(Product.count, 'Product') %>"
  end
end
