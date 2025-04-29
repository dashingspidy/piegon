class CampaignEvent < ApplicationRecord
  belongs_to :campaign
  belongs_to :subscriber

  before_create :skip_duplicate_open_event
  after_commit :update_location, on: :create, if: :open_event?

  private

  def open_event?
    event_type == "open"
  end

  def skip_duplicate_open_event
    if open_event? && CampaignEvent.find_by(campaign_id: campaign_id, subscriber_id: subscriber_id, event_type: "open").present?
      throw(:abort)
    end
  end

  def update_location
    if ip_address.present?
      update_column(:location, Geocoder.search(ip_address).first&.country || "Unknown")
    end
  end
end
