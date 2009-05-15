controller.headers["Content-Type"] = "text/plain"

xml.dl do
  show(xml, "distance_of_time_in_words(Time.now, Time.local(2005, 12, 25))")
  show(xml, "distance_of_time_in_words(Time.now, Time.now + 33, false)")
  show(xml, "distance_of_time_in_words(Time.now, Time.now + 33, true)")
  show(xml, "time_ago_in_words(Time.local(2004, 12, 25))")
end

