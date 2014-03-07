class SArticleContent < RubyDbConnecter
  # attr_accessible :title, :body
  set_table_name "article_contents"
  set_primary_key "id"
end
