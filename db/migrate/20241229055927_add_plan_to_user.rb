class AddPlanToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :plan, :string
    add_column :users, :email_limit, :integer
  end
end
