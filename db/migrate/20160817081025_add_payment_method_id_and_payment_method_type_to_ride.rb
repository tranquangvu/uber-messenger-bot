class AddPaymentMethodIdAndPaymentMethodTypeToRide < ActiveRecord::Migration[5.0]
  def change
    add_column :rides, :payment_method_type, :string
    add_column :rides, :payment_method_id, :string
  end
end
