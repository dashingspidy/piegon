class HomeController < ApplicationController
  allow_unauthenticated_access only: [ :index, :beta ]
  before_action :resume_session, only: [ :index ]

  def index
  end

  def beta
    render layout: false
  end
end
