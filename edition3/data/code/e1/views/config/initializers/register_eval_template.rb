require "eval_template"
ActionView::Template.register_template_handler("reval", EvalTemplate)
