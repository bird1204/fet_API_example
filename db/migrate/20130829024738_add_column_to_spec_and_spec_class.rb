class AddColumnToSpecAndSpecClass < ActiveRecord::Migration
  def change
    add_column :specs , :spec_id , :integer
    add_column :spec_classes , :spec_class_id , :integer
  end
end
