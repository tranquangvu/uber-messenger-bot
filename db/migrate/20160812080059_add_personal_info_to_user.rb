class AddPersonalInfoToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :email, :string
    add_column :users, :promo_code, :string
    add_column :users, :uuid, :string
  end
end
