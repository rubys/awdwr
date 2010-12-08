class Product < ActiveRecord::Base
  
  has_one :detail
  
  validates_presence_of :title
  
end
