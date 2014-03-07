class CreateSpecClasses < ActiveRecord::Migration
  def change
    create_table :spec_classes do |t|
      t.string :name
      t.string :name_en
      t.integer :sort
      t.integer :hall_id
      t.timestamps
    end
    add_index :spec_classes,:hall_id
  end
end
