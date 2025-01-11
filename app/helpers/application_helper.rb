module ApplicationHelper
  include Pagy::Frontend
  def active_link(url_path)
    "active" if request.path.start_with?(url_path)
  end

  def number_to_k(number)
    number_to_human(number, format: "%n%u", units: { thousand: "K" })
  end

  def free_account
    Current.user.plan == "free"
  end
end
