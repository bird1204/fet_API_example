class TwGemArticle < TwSogiConnecter
  # attr_accessible :title, :body
  set_table_name "articles"
  set_primary_key "id"
end

