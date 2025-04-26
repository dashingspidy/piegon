class DashboardController < ApplicationController
  def index
    if params[:order_id] && params[:customer_id]
      Current.user.update!(customer_id: params[:customer_id])
    end
    @contact_count = Current.user.contacts.size
    @total_subscribers = Current.user.contacts.sum { |c| c.subscribers.size }
    @new_subscribers = Current.user.contacts.sum { |c| c.subscribers.where("created_at >= ?", 1.week.ago).size }
    @unsubscribed_count = Current.user.contacts.sum { |c| c.subscribers.where(unsubscribed: true).size }
    @scheduled_campaigns = Current.user.campaigns.where(finished: false, running: false).count
    @running_campaigns = Current.user.campaigns.where(running: true).size
    @completed_campaigns = Current.user.campaigns.where(finished: true).size
  end
end
