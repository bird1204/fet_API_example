class CreateProductImages < ActiveRecord::Migration
  def change
    create_table :product_images do |t|

      t.integer :categorized
      t.string :imageable_type
      t.integer :imageable_id
      t.string :file
      t.string :type_text, default: "product"
      t.string :url_origin
      t.string :url_big
      t.string :url_medium
      t.string :url_small
      t.string :url_thumb

      t.timestamps
    end
    add_index :product_images,:imageable_id
  end
end
