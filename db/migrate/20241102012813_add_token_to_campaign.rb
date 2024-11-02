class AddTokenToCampaign < ActiveRecord::Migration[8.0]
  def change
    add_column :campaigns, :api_token, :string
  end
end
