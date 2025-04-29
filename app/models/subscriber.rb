class Subscriber < ApplicationRecord
  belongs_to :contact
  has_many :campaign_events, dependent: :destroy

  validates :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Not a valid email address" }
  validate :unique_email_by_contact

  scope :subscribed, -> { where(unsubscribed: false) }

  private

  def unique_email_by_contact
    return unless contact
    if contact.subscribers.where.not(id: id).exists?(email: email)
      errors.add(:email, "Email already subscribed.")
    end
  end
end
