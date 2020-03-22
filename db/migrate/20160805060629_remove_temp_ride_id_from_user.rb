class RemoveTempRideIdFromUser < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :temp_ride_id, :integer
  end
end
