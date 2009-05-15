# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

#START:register
require "rdoc_template"

ActionView::Template.register_template_handler("rdoc", RDocTemplate)
#END:register

require "eval_template"
ActionView::Template.register_template_handler("reval", EvalTemplate)


class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '0e61f18fcfce07c841a09b8ea9b1a333'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
end
