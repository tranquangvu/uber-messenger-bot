class AddProductIdToRide < ActiveRecord::Migration[5.0]
  def change
    add_column :rides, :product_id, :string
  end
end
