class SGemArticle < RubyDbConnecter
  # attr_accessible :title, :body
  set_table_name "gem_articles"
  set_primary_key "id"
end
