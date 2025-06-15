module ArticlesHelper
  def render_html(text)
    return "" if text.blank?

    # Since content is already in HTML format, just sanitize and return
    # You can add HTML sanitization here if needed
    text.html_safe
  end

  def html_excerpt(text, limit = 160)
    return "" if text.blank?

    # Strip HTML tags for excerpt
    plain_text = ActionController::Base.helpers.strip_tags(text).strip
    truncate(plain_text, length: limit)
  end
end
