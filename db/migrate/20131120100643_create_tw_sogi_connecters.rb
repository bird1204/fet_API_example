class CreateTwSogiConnecters < ActiveRecord::Migration
  def change
    create_table :tw_sogi_connecters do |t|

      t.timestamps
    end
  end
end
