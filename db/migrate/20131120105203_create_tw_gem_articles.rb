class CreateTwGemArticles < ActiveRecord::Migration
  def change
    create_table :tw_gem_articles do |t|

      t.timestamps
    end
  end
end
