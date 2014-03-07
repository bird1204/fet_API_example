class Spec < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :spec_class
  has_many :product_spec_displays
  set_primary_key :spec_id

end
