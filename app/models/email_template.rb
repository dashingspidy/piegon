class EmailTemplate < ApplicationRecord
  belongs_to :user
  validates :name, presence: true, uniqueness: true
  has_many_attached :images, dependent: :purge_later
end
