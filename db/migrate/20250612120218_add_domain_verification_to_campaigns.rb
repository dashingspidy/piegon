class AddDomainVerificationToCampaigns < ActiveRecord::Migration[8.0]
  def change
    add_reference :campaigns, :domain_verification, null: true, foreign_key: true
  end
end
