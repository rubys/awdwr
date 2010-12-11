controller.headers["Content-Type"] = "text/plain"

xml.dl do
  show(xml, "debug(@params)")
end