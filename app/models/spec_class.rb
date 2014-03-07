class SpecClass < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :specs
  has_many :product_spec_displays ,:through => :specs
  set_primary_key :spec_class_id
end
