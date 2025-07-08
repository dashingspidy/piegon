class EmailTemplate < ApplicationRecord
  belongs_to :user
  has_many :campaigns, dependent: :restrict_with_error
  has_rich_text :body
  validates :name, presence: true, uniqueness: true
end
