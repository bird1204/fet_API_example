class SProduct < RubyDbConnecter
  set_table_name "products"
  set_primary_key "id"

  has_many :s_product_spec_displays,:foreign_key => "product_id"
  has_many :s_product_image,:foreign_key => "imageable_id"

end