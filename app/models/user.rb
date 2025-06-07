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
  has_one :mail_setting, dependent: :destroy
  has_many :domain_verifications, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, if: :password_required?

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

  def self.from_omniauth(auth, plan = "free")
    where(email_address: auth.info.email).first_or_create do |user|
      user.email_address = auth.info.email
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.plan = plan
      user.confirmed_at = Time.current
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
