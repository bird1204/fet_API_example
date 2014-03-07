class SSpecClass < RubyDbConnecter
  # attr_accessible :title, :body
  has_many :s_spec,:foreign_key => "spec_class_id"
  set_table_name "spec_classes"
  set_primary_key "id"
end
