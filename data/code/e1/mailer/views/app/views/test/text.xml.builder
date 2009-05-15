controller.headers["Content-Type"] = "text/plain"

xml.dl do
  @text = %{
     E-Mail dave@pragprog.com, or visit
     http://pragprog.com/contact for 
     phone numbers and other details.
  }
  show(xml, "auto_link(@text)")

@trees = %{
I think that I shall never see
A poem lovely as a tree.

A tree whose hungry mouth is prest
Against the sweet earth's flowing breast;
}#'

  show(xml, %{excerpt(@trees, "lovely", 8)})
  show(xml, %{highlight(@trees, "tree")})
  show(xml, %{truncate(@trees, 20)})
  show(xml, %{simple_format(@trees)})

@bluetext = %{
Greetings
=========

Things to do:

* wash cat
* walk iguana
* straighten worm
}

  show(xml, %{markdown(@bluetext)})
  show(xml, %{pluralize(1, "person")})
  show(xml, %{pluralize(2, "person")})


  @linked_text = %{See <a href="http://pragprog.com">our site</a>.}
show(xml, "strip_links(@linked_text)")

@redtext = %{
Things to do:

* wash cat
* walk iguana
* straighten worm
}
  show(xml, %{textilize_without_paragraph(@redtext)})
end
