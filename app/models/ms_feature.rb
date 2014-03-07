class MsFeature < MssqlConnecter
  belongs_to :ms_product,:foreign_key => "p_no"
  set_table_name "FET_Features"
  set_primary_key "p_no"
end
