class Campaign < ApplicationRecord
  belongs_to :user
  has_many :subscribers
  has_one :csv_uploader
  has_secure_token :api_token

  validates_presence_of :name
  validates_uniqueness_of :api_token, :name
end
