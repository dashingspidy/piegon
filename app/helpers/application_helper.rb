module ApplicationHelper
  include Pagy::Frontend
  def active_link(url_path)
    "active" if request.path == url_path
  end

  def number_to_k(number)
    number_to_human(number, format: "%n%u", units: { thousand: "K" })
  end
end
