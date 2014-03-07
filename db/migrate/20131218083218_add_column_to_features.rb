class AddColumnToFeatures < ActiveRecord::Migration
  def change
    add_column :features , :features11 , :boolean
    add_column :features , :features12 , :boolean
  end
end
