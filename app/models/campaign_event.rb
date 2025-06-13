class CampaignEvent < ApplicationRecord
  belongs_to :campaign
  belongs_to :subscriber

  # Define valid event types from SendGrid
  VALID_EVENT_TYPES = %w[
    send processed delivered open click bounce dropped deferred
    spam unsubscribe group_unsubscribe group_resubscribe
  ].freeze

  validates :event_type, inclusion: { in: VALID_EVENT_TYPES }
  validates :sendgrid_event_id, uniqueness: true, allow_nil: true

  before_create :skip_duplicate_open_event
  after_commit :update_location, on: :create, if: :should_update_location?

  scope :delivered, -> { where(event_type: "delivered") }
  scope :opened, -> { where(event_type: "open") }
  scope :clicked, -> { where(event_type: "click") }
  scope :bounced, -> { where(event_type: "bounce") }
  scope :dropped, -> { where(event_type: "dropped") }
  scope :spam_reports, -> { where(event_type: "spam") }
  scope :unsubscribed, -> { where(event_type: "unsubscribe") }

  def delivered?
    event_type == "delivered"
  end

  def opened?
    event_type == "open"
  end

  def clicked?
    event_type == "click"
  end

  def bounced?
    event_type == "bounce"
  end

  def spam_report?
    event_type == "spam"
  end

  def engagement_event?
    %w[open click].include?(event_type)
  end

  def delivery_event?
    %w[processed delivered bounce dropped deferred].include?(event_type)
  end

  private

  def open_event?
    event_type == "open"
  end

  def should_update_location?
    open_event? && ip_address.present? && location.blank?
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
