class MsProduct < MssqlConnecter
  has_one :ms_feature,:foreign_key => "p_no"
  has_many :ms_product_spec_display,:foreign_key => "p_no"
  set_table_name "FET_Product"
  set_primary_key "id"
end
