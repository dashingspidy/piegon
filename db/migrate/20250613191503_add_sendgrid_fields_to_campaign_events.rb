class AddSendgridFieldsToCampaignEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :campaign_events, :sendgrid_event_id, :string
    add_column :campaign_events, :reason, :string # For bounces/drops
    add_column :campaign_events, :url, :string # For clicks
    add_column :campaign_events, :email_client, :string
    add_column :campaign_events, :category, :string # Custom categories
    add_column :campaign_events, :unique_args, :json # SendGrid unique args
    add_column :campaign_events, :timestamp, :bigint # SendGrid event timestamp
    add_column :campaign_events, :smtp_id, :string # SendGrid SMTP ID

    add_index :campaign_events, :sendgrid_event_id, unique: true
    add_index :campaign_events, :event_type
    add_index :campaign_events, :timestamp
  end
end
