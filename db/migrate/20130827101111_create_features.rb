class CreateFeatures < ActiveRecord::Migration
  def change
    create_table :features do |t|
      t.integer :product_id
      t.integer :os
      t.boolean :features1
      t.boolean :features2
      t.boolean :features3
      t.boolean :features4
      t.boolean :features5
      t.boolean :features6
      t.boolean :features7
      t.boolean :features8
      t.boolean :features9
      t.boolean :features10

      t.timestamps
    end
    add_index :features,:product_id
  end
end
