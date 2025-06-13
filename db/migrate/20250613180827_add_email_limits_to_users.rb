class AddEmailLimitsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :emails_sent, :integer, default: 0
    add_column :users, :additional_emails, :integer, default: 0
  end
end
