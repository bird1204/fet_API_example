class ProductSpecDisplay < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :product
  belongs_to :spec
end
