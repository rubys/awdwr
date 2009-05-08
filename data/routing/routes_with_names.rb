ActionController::Routing::Routes.draw do |map| 
  
  # Straight 'http://my.app/blog/' displays the index 
  map.index "blog/", 
            :controller => "blog", 
            :action => "index" 

  # Return articles for a year, year/month, or year/month/day 
  map.date "blog/:year/:month/:day", 
           :controller => "blog", 
           :action => "show_date", 
           :requirements => { :year => /(19|20)\d\d/,
                              :month => /[01]?\d/, 
                              :day => /[0-3]?\d/}, 
           :day => nil, 
           :month => nil 

  #START:show_article
  # Show an article identified by an id 
  map.show_article "blog/show/:id", 
                   :controller => "blog", 
                   :action => "show", 
                   :id => /\d+/ 
  #END:show_article
                
  # Regular Rails routing for admin stuff 
  #START:admin
  map.blog_admin "blog/:controller/:action/:id" 
  #END:admin

  # Catchall so we can gracefully handle badly formed requests 
  map.catch_all "*anything", 
                :controller => "blog", 
                :action => "unknown_request" 
end
