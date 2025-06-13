class User < ApplicationRecord
  include DisposableEmailCheck
  has_secure_password validations: false
  has_secure_token :confirmation_token
  has_many :sessions, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :email_templates, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :replies, dependent: :destroy

  has_many :domain_verifications, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, if: :password_required?
  validates :emails_sent, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :additional_emails, presence: true, numericality: { greater_than_or_equal_to: 0 }

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

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end

  def plan_object
    Plan.new(plan || "free")
  end

  def limit_reached?(resource)
    current_count = public_send(resource).count
    current_count >= plan_object.limit_for(resource)
  end

  # Email limit methods
  def email_limit
    plan_object.limit_for(:email_limit)
  end

  def total_available_emails
    email_limit + additional_emails
  end

  def emails_remaining
    total_available_emails - emails_sent
  end

  def can_send_emails?(count = 1)
    emails_remaining >= count
  end

  def use_emails!(count)
    if can_send_emails?(count)
      increment!(:emails_sent, count)
      true
    else
      false
    end
  end

  def purchase_additional_emails!(count)
    increment!(:additional_emails, count)
  end

  def reset_email_count!
    update!(emails_sent: 0)
  end

  def email_usage_percentage
    return 0 if total_available_emails.zero?
    (emails_sent.to_f / total_available_emails.to_f * 100).round(2)
  end

  def self.from_omniauth(auth, plan = "free")
    where(email_address: auth.info.email).first_or_create do |user|
      user.email_address = auth.info.email
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.plan = plan
      user.confirmed_at = Time.current
      user.emails_sent = 0
      user.additional_emails = 0
    end
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  private

  def password_required?
    !oauth_user? && (password_digest.blank? || !password.blank?)
  end
end
