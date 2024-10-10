class Campaign < ApplicationRecord
  belongs_to :user
  has_many :subscribers
  has_one :csv_uploader

  validates_presence_of :name
end
