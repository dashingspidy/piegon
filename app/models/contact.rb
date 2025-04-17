class Contact < ApplicationRecord
  belongs_to :user
  has_many :subscribers, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_one :csv_uploader
  has_secure_token :api_token

  validates_presence_of :name
  validates_uniqueness_of :api_token, :name
end
