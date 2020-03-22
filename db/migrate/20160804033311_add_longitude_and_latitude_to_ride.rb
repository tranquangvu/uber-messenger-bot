class AddLongitudeAndLatitudeToRide < ActiveRecord::Migration[5.0]
  def change
    add_column :rides, :location_longitude, :float
    add_column :rides, :location_latitude, :float
    add_column :rides, :destination_longitude, :float
    add_column :rides, :destination_latitude, :float
  end
end
