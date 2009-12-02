require 'rdoc/markup'
require 'rdoc/markup/to_html'

class RDocTemplate < ActionView::TemplateHandler
  def render(template, local_assigns = {})
    markup    = RDoc::Markup.new
    generator = RDoc::Markup::ToHtml.new
    markup.convert(template.source, generator)
  end
end
