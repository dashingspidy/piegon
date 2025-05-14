class EmailTemplate < ApplicationRecord
  belongs_to :user
  has_rich_text :body
  validates :name, presence: true, uniqueness: true
end
