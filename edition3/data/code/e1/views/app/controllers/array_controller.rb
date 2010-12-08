class ArrayController < ApplicationController
  def edit
    if request.post?
      #START:edit
      Product.update(params[:product].keys, params[:product].values)
      #END:edit
    end
    @products = Product.find(:all)
  end
end
