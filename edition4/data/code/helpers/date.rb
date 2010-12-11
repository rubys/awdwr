require 'active_support/all'
require 'action_view'
include ActionView::Helpers::DateHelper
distance_of_time_in_words(Time.now, Time.local(2010, 12, 25))
distance_of_time_in_words(Time.now, Time.now + 33, false)
distance_of_time_in_words(Time.now, Time.now + 33, true)
time_ago_in_words(Time.local(2009, 12, 25))
