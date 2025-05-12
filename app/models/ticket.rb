class Ticket < ApplicationRecord
  belongs_to :user
  has_many :replies

  validates_presence_of :subject, :description
end
