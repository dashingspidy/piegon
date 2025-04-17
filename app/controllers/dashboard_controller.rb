class DashboardController < ApplicationController
  def index
    @contact_count = Current.user.contacts.size
    @total_subscribers = Current.user.contacts.sum { |c| c.subscribers.size }
  end
end
