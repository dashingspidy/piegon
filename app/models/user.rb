class User < ApplicationRecord
  has_secure_password
  has_secure_token :confirmation_token
  has_many :sessions, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :email_templates, dependent: :destroy
  has_many :email_logs

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end

  def confirmed?
    confirmed_at.present?
  end

  def send_confirmation_instructions
    regenerate_confirmation_token
    UserMailer.confirmation_instructions(self).deliver_later
  end
end
