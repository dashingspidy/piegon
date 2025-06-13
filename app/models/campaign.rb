class Campaign < ApplicationRecord
  belongs_to :contact
  belongs_to :user
  belongs_to :email_template
  belongs_to :domain_verification, optional: true
  has_many :campaign_events, dependent: :destroy
  has_many :subscribers, through: :contact

  attr_accessor :send_time_option
  before_save :set_send_time
  validate :user_has_sufficient_email_credits

  validates_presence_of :name, :subject, :header, :from, :contact_id, :email_template_id
  validates :send_at, presence: true, unless: -> { send_time_option == "now" }
  validate :send_time_in_future, if: -> { send_at.present? && send_time_option == "later" }

  def send_time_in_future
    if send_at < Time.current
      errors.add(:send_at, "Select a future date")
    end
  end

  def user_has_sufficient_email_credits
    return unless contact # Skip validation if contact is not set yet

    recipient_count = contact.subscribers.subscribed.count
    return if recipient_count.zero? # No subscribers to send to

    unless user.can_send_emails?(recipient_count)
      remaining = user.emails_remaining
      errors.add(:base, "Insufficient email credits. You need #{recipient_count} credits but only have #{remaining} remaining. Please upgrade your plan or purchase additional emails.")
    end
  end

  def estimated_email_cost
    contact&.subscribers&.subscribed&.count || 0
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

  def total_processed
    total_events("processed")
  end

  def total_delivered
    total_events("delivered")
  end

  def total_opened
    total_events("open")
  end

  def total_clicked
    total_events("click")
  end

  def total_bounced
    total_events("bounce")
  end

  def total_dropped
    total_events("dropped")
  end

  def total_spam_reports
    total_events("spam")
  end

  def total_unsubscribed
    total_events("unsubscribe")
  end

  # Enhanced percentage calculations
  def delivery_rate
    total_processed.zero? ? 0 : (total_delivered.to_f / total_processed.to_f * 100).round(2)
  end

  def open_rate
    total_delivered.zero? ? 0 : (total_opened.to_f / total_delivered.to_f * 100).round(2)
  end

  def click_rate
    total_delivered.zero? ? 0 : (total_clicked.to_f / total_delivered.to_f * 100).round(2)
  end

  def click_to_open_rate
    total_opened.zero? ? 0 : (total_clicked.to_f / total_opened.to_f * 100).round(2)
  end

  def bounce_rate
    total_processed.zero? ? 0 : (total_bounced.to_f / total_processed.to_f * 100).round(2)
  end

  def spam_rate
    total_delivered.zero? ? 0 : (total_spam_reports.to_f / total_delivered.to_f * 100).round(2)
  end

  def unsubscribe_rate
    total_delivered.zero? ? 0 : (total_unsubscribed.to_f / total_delivered.to_f * 100).round(2)
  end

  # Legacy methods for backward compatibility
  def open_percentage
    open_rate
  end

  def bounce_percentage
    bounce_rate
  end

  # Enhanced analytics
  def country_distribution
    campaign_events.where(event_type: "open").group(:location).count.transform_keys { |code| ISO3166::Country[code]&.common_name || "Unknown" }
  end

  def device_distribution
    campaign_events.where(event_type: "open").group(:user_agent).count
  end

  def email_client_distribution
    campaign_events.where(event_type: "open").where.not(email_client: [ nil, "" ]).group(:email_client).count
  end

  def click_url_distribution
    campaign_events.where(event_type: "click").where.not(url: [ nil, "" ]).group(:url).count
  end

  def bounce_reason_distribution
    campaign_events.where(event_type: "bounce").where.not(reason: [ nil, "" ]).group(:reason).count
  end

  def hourly_engagement
    # SQLite-compatible hour extraction
    campaign_events.where(event_type: [ "open", "click" ])
                   .group("strftime('%H', occurred_at)")
                   .group(:event_type)
                   .count
  end

  def daily_activity
    # SQLite-compatible date extraction
    campaign_events.where(occurred_at: 30.days.ago..Time.current)
                   .group("date(occurred_at)")
                   .group(:event_type)
                   .count
  end

  private

  def set_send_time
    if send_time_option == "now"
      self.send_at = Time.current
    end
  end
end
