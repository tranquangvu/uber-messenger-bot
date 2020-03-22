class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :messenger_id
      t.string :access_token
      t.string :refresh_token
      t.integer :expires_in
      t.datetime :token_created_at
    end
  end
end
