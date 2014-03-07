class SSpec < RubyDbConnecter
  # attr_accessible :title, :body
  belongs_to :s_spec_class,:foreign_key => "spec_class_id"
  has_many :s_product_spec_displays,:foreign_key => "spec_id"
  set_table_name "specs"
  set_primary_key "id"
end
