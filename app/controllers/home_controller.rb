class HomeController < ApplicationController
  allow_unauthenticated_access only: [ :index ]
  before_action :resume_session, only: [ :index ]

  def index
  end
end
