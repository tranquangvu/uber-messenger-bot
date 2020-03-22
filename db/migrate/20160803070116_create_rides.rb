class CreateRides < ActiveRecord::Migration[5.0]
  def change
    create_table :rides do |t|
      t.string :location
      t.string :destination
      t.references :user, foreign_key: true, index: true

      t.timestamps
    end
  end
end
