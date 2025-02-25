class MailSetting < ApplicationRecord
  belongs_to :user

  encrypts :password

  validates_presence_of :host, :username, :password
  validates_uniqueness_of :user_id, message: "can only have one mail setting"

  def to_smtp_settings
    {
      address: host,
      port: port,
      user_name: username,
      password: password,
      authentication: "plain",
      enable_starttls_auto: true
    }
  end
end
