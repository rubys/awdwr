#START:get
class UploadController < ApplicationController
  def get
    @picture = Picture.new
  end
  # . . .
#END:get

#START:save
  def save
    @picture = Picture.new(params[:picture])
    if @picture.save
      redirect_to(:action => 'show', :id => @picture.id)
    else
      render(:action => :get)
    end
  end
#END:save

#START:show
  def show
    @picture = Picture.find(params[:id])
  end
#END:show

#START:picture
  def picture
    @picture = Picture.find(params[:id])
    send_data(@picture.data,
              :filename => @picture.name,
              :type => @picture.content_type,
              :disposition => "inline")
  end
#END:picture
#START:get
end
#END:get
