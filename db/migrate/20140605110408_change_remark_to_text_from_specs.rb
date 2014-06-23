class ChangeRemarkToTextFromSpecs < ActiveRecord::Migration
  def change
    change_column :specs, :remark ,:text
  end
end
