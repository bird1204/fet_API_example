class SBrand < RubyDbConnecter
  # attr_accessible :title, :body
  set_table_name "brands"
  set_primary_key "id"
end
