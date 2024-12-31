class HomeController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session, only: [ :index ]

  def index
  end

  def privacy
  end

  def terms
  end
end
