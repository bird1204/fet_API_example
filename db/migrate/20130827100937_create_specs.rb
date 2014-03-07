class CreateSpecs < ActiveRecord::Migration
  def change
    create_table :specs do |t|
      t.string :name
      t.string :name_en
      t.integer :spec_class_id
      t.string :remark
      t.integer :sort

      t.timestamps
    end

    add_index :specs,:spec_class_id
  end
end
