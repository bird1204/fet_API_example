class SProductImage < RubyDbConnecter
  belongs_to :s_product,:foreign_key => "imageable_id"
  set_table_name "product_images"
  set_primary_key "id"
end
