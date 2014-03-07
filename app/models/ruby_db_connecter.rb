class RubyDbConnecter < ActiveRecord::Base
  # see
  # http://stackoverflow.com/questions/6122508/connecting-rails-3-1-with-multiple-databases
  self.abstract_class = true
  establish_connection "ruby_db"
end
