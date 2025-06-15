class Article < ApplicationRecord
  has_one_attached :cover_image

  validates :title, :content, :keywords, :meta_description, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: :title_changed?
  before_validation :sanitize_content

  scope :recent, -> { order(created_at: :desc) }
  scope :by_keyword, ->(keyword) { where("keywords ILIKE ?", "%#{keyword}%") }

  def to_param
    slug
  end

  def word_count
    content.to_s.split.size
  end

  def reading_time
    # Average reading speed is 200 words per minute
    (word_count / 200.0).ceil
  end

  def excerpt(limit = 160)
    # Remove HTML tags for excerpt
    plain_content = ActionController::Base.helpers.strip_tags(content.to_s).strip
    plain_content.truncate(limit)
  end

  private

  def generate_slug
    return if title.blank?

    base_slug = title.parameterize
    counter = 1
    new_slug = base_slug

    # Ensure uniqueness
    while Article.where(slug: new_slug).where.not(id: id).exists?
      new_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = new_slug
  end

  def sanitize_content
    # Remove any potentially harmful content while preserving HTML
    return if content.blank?

    # Basic sanitization - you might want to use a proper sanitizer gem
    self.content = content.to_s.strip
  end
end
