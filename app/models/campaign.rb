class Campaign < ApplicationRecord
  belongs_to :contact
  belongs_to :user
  belongs_to :email_template
  belongs_to :domain_verification, optional: true
  has_many :campaign_events, dependent: :destroy
  has_many :subscribers, through: :contact

  attr_accessor :send_time_option
  before_save :set_send_time

  validates_presence_of :name, :subject, :header, :from, :contact_id, :email_template_id
  validates :send_at, presence: true, unless: -> { send_time_option == "now" }
  validate :send_time_in_future, if: -> { send_at.present? && send_time_option == "later" }

  def send_time_in_future
    if send_at < Time.current
      errors.add(:send_at, "Select a future date")
    end
  end

  def verified_domain
    domain_verification || user.domain_verifications.verified.first
  end

  def sender_domain
    verified_domain&.domain || "piegon.pro"
  end

  def full_from_address
    # Sanitize header to remove problematic characters
    sanitized_header = header.to_s.gsub(/[<>"\\\r\n]/, "").strip

    # Check if from field already contains a complete email address
    if from.include?("@")
      # from field already has domain, use as-is
      email_address = from.strip
    else
      # from field is just local part, add domain
      email_address = "#{from.strip}@#{sender_domain}"
    end

    if sanitized_header.present?
      "#{sanitized_header} <#{email_address}>"
    else
      email_address
    end
  end

  def using_verified_domain?
    verified_domain.present?
  end

  def total_events(event_type)
    campaign_events.where(event_type: event_type).count
  end

  def total_sent
    total_events("send")
  end

  def total_opened
    total_events("open")
  end

  def total_bounced
    total_events("bounce")
  end

  def open_percentage
    total_sent.zero? ? 0 : (total_opened.to_f / total_sent.to_f * 100).round(2)
  end

  def bounce_percentage
    total_sent.zero? ? 0 : (total_bounced.to_f / total_sent.to_f * 100).round(2)
  end

  def country_distribution
    campaign_events.where(event_type: "open").group(:location).count.transform_keys { |code| ISO3166::Country[code]&.common_name || "Unknown" }
  end

  def device_distribution
    campaign_events.where(event_type: "open").group(:user_agent).count
  end

  private

  def set_send_time
    if send_time_option == "now"
      self.send_at = Time.current
    end
  end
end
