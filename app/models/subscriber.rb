class Subscriber < ApplicationRecord
  belongs_to :campaign

  validates :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Not a valid email address" }
  validate :unique_email_by_campaign

  private

  def unique_email_by_campaign
    if campaign.subscribers.where.not(id: id).exists?(email: email)
      errors.add(:email, "Email already subscribed.")
    end
  end
end
