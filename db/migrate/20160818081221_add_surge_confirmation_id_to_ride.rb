class AddSurgeConfirmationIdToRide < ActiveRecord::Migration[5.0]
  def change
    add_column :rides, :surge_confirmation_id, :string
  end
end
