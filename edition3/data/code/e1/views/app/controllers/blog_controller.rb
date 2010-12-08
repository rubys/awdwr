#START:original
class BlogController < ApplicationController
  def list
    @dynamic_content = Time.now.to_s
  end
end
#END:original

class BlogController < ApplicationController
  def flush
#START:expire
    expire_fragment(:controller => 'blog', :action => 'list')
#END:expire
    render(:text => "Toast")
  end
end
