class Contact < ApplicationRecord
  belongs_to :user
  has_many :campaigns, dependent: :destroy
  has_many :subscribers, dependent: :delete_all
  has_one :csv_uploader, dependent: :destroy

  # Add association to campaign_events through both campaigns and subscribers
  has_many :campaign_events, through: :campaigns
  has_many :subscriber_campaign_events, through: :subscribers, source: :campaign_events

  has_secure_token :api_token

  validates_presence_of :name
  validates_uniqueness_of :api_token, :name

  before_destroy :cleanup_campaign_events

  private

  def cleanup_campaign_events
    CampaignEvent.where(
      campaign_id: campaigns.select(:id)
    ).or(
      CampaignEvent.where(
        subscriber_id: subscribers.select(:id)
      )
    ).delete_all
  end
end
