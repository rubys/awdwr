class FormForController < ApplicationController

  def new
    @product = Product.new
  end

  def create
  end
end
