module ApplicationHelper
  def active_link(url_path)
    "active" if request.path == url_path
  end
end
