class HomeController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session, only: [ :index ]

  def index
    redirect_to dashboard_path if authenticated?
  end

  def privacy
  end

  def terms
  end

  def help
  end
end
