require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/inline'
require 'rdoc/markup/simple_markup/to_html'

class RDocTemplate < ActionView::TemplateHandler
  def render(template)
    markup    = SM::SimpleMarkup.new
    generator = SM::ToHtml.new
    markup.convert(template.source, generator)
  end
end
