class AddTempRideIdToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :temp_ride_id, :integer
  end
end
