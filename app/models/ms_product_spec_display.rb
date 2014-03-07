class MsProductSpecDisplay < MssqlConnecter
  belongs_to :ms_product,:foreign_key => "p_no"
  set_table_name "FET_Specification_Value"
  set_primary_key "sv_no"
end
