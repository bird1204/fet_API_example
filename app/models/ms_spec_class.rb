class MsSpecClass < MssqlConnecter
  # attr_accessible :title, :body
  has_many :ms_specs,:foreign_key => "sc_no"
  set_table_name "FET_Specification_Class"
  set_primary_key "sc_no"
end
