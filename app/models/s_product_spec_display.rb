class SProductSpecDisplay < RubyDbConnecter
  # attr_accessible :title, :body
  belongs_to :s_product,:foreign_key => "product_id"
  belongs_to :s_spec,:foreign_key => "spec_id"
  set_table_name "product_spec_displays"
  set_primary_key "id"
end
