class ProductsController < ApplicationController

  #START:new
  def new
    @product = Product.new
    @details = Detail.new
  end
  #END:new
  
  #START:create
  def create
    @product = Product.new(params[:product])
    @details = Detail.new(params[:details])

    Product.transaction do
      @product.save!
      @details.product = @product
      @details.save!
      redirect_to :action => :show, :id => @product
    end

  rescue ActiveRecord::RecordInvalid => e
    @details.valid?   # force checking of errors even if products failed
    render :action => :new
  end
  #END:create
  
  def show
    @product = Product.find(params[:id])
  end
end
