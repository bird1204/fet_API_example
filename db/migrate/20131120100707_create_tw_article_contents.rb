class CreateTwArticleContents < ActiveRecord::Migration
  def change
    create_table :tw_article_contents do |t|

      t.timestamps
    end
  end
end
