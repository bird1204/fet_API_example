class ChangeInfoToTextFromProduct < ActiveRecord::Migration
  def change
    change_column :products,:info ,:text
  end
end
