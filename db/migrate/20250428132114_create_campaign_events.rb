class CreateCampaignEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :campaign_events do |t|
      t.string :event_type, null: false
      t.string :ip_address
      t.string :user_agent
      t.string :location
      t.datetime :occurred_at
      t.references :campaign, null: false, foreign_key: true
      t.references :subscriber, null: false, foreign_key: true

      t.timestamps
    end
  end
end
