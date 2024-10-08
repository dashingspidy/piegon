class CreateScheduleCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :schedule_campaigns do |t|
      t.references :campaign, null: false, foreign_key: true
      t.datetime :send_at, default: DateTime.now

      t.timestamps
    end
  end
end
