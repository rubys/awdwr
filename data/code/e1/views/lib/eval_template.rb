class EvalTemplate < ActionView::TemplateHandler
  def render(template, local_assigns = {})
    # create get a binding for @view
    bind = @view.send(:binding)

    # and local variables if we're a partial
    local_assigns.each do |key, value|
      eval("#{key} = #{value}", bind)
    end

    @view.controller.headers["Content-Type"] = 'text/plain'

    # evaluate each line and show the original alongside
    # its value
    template.source.split(/\n/).map do |line|
      begin
        line + " => " + eval(line, bind).to_s
      rescue Exception => err
        line + " => " + err.inspect
      end
    end.join("\n")
  end
end
