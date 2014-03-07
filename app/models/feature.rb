class Feature < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :product,:foreign_key => "product_id"
end
