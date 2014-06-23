class ChangeReviewsToTextFromProduct < ActiveRecord::Migration
  def change
    change_column :products,:reviews ,:text
  end
end
