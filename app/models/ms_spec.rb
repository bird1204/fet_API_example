class MsSpec < MssqlConnecter
  belongs_to :ms_spec_class,:foreign_key => "sc_no"
  set_table_name "FET_Specification"
  set_primary_key "s_no"
end
