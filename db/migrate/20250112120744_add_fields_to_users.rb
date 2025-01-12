class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :subscription_id, :integer
    add_column :users, :next_payment_date, :datetime
    add_column :users, :subscription_status, :string
  end
end
