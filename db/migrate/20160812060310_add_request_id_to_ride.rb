class AddRequestIdToRide < ActiveRecord::Migration[5.0]
  def change
    add_column :rides, :request_id, :string
  end
end
