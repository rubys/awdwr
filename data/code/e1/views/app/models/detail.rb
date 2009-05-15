class Detail < ActiveRecord::Base
  belongs_to :product
  validates_presence_of :sku
end
