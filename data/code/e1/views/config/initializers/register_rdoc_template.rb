require 'rdoc_template'
ActionView::Template.register_template_handler('rdoc', RDocTemplate)
