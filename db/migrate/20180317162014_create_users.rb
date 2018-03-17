class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :username
      t.string :primary_trait
      t.string :secondary_trait
      t.string :tertiary_trait
      t.string :music_recomendation

      t.timestamps
    end
  end
end
