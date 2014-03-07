class CreateProductSpecDisplays < ActiveRecord::Migration
  def change
    create_table :product_spec_displays do |t|
      t.integer :product_id
      t.string :name
      t.integer :spec_id
      t.timestamps
    end
    add_index :product_spec_displays,:product_id
    add_index :product_spec_displays,:spec_id
  end
end
