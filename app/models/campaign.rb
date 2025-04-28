class Campaign < ApplicationRecord
  belongs_to :contact
  belongs_to :user
  belongs_to :email_template

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

  private

  def set_send_time
    if send_time_option == "now"
      self.send_at = Time.current
    end
  end
end
