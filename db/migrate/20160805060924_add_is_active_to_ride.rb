class AddIsActiveToRide < ActiveRecord::Migration[5.0]
  def change
    add_column :rides, :active, :boolean, default: true
  end
end
