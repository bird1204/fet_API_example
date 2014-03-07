class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :info
      t.integer :product_type
      t.integer :brand_id
      t.integer :reviews
      t.string :market_date
      t.boolean :status
      t.boolean :is_info_trans
      t.boolean :is_spec_trans
      t.boolean :is_pic_trans

      t.timestamps
    end
    add_index :products, :brand_id
  end
end
