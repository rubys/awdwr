require 'rdoc'
require 'rdoc/markup'
require 'rdoc/markup/to_html'

class RDocTemplate < ActionView::TemplateHandler
  include ActionView::TemplateHandlers::Compilable
  def compile(template)
    markup    = RDoc::Markup.new
    generator = RDoc::Markup::ToHtml.new
    markup.convert(template.source, generator).inspect
  end
end
