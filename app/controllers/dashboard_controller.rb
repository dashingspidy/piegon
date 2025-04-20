class DashboardController < ApplicationController
  def index
    if params[:order_id] && params[:customer_id]
      Current.user.update!(customer_id: params[:customer_id])
    end
    @contact_count = Current.user.contacts.size
    @total_subscribers = Current.user.contacts.sum { |c| c.subscribers.size }
    @total_campaigns = Current.user.campaigns.size
  end
end
