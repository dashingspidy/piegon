class DashboardController < ApplicationController
  def index
    if params[:subscription_id] && params[:product_id]
      handle_subscription_update
    end
    @campaign_count = Current.user.campaigns.size
    @total_subscribers = Current.user.campaigns.sum { |c| c.subscribers.size }
    @emails_sent_this_month = Current.user.email_logs.where("created_at >= ?", Time.current.beginning_of_month).count

    if Current.user.plan == "free"
      @email_limit = 100
      @remaining_emails = 100
    elsif Current.user.plan == "lifetime"
      @email_limit = "Unlimited"
      @remaining_emails = "Unlimited"
    else
      @email_limit = Current.user.email_limit
      @remaining_emails = [ @email_limit.to_i - @emails_sent_this_month, 0 ].max
    end
  end

  private

  def handle_subscription_update
    product_id = params[:product_id]
    subscription_id = params[:subscription_id]

    plan_name = nil
    Payment::PRODUCTS.each do |plan, details|
      if details[:id] == product_id
        plan_name = plan
        break
      end
    end

    if plan_name
      email_limit = Payment::PRODUCTS[plan_name][:email_limit]

      Current.user.update(
        plan: plan_name,
        email_limit: email_limit,
        subscription_id: subscription_id,
        subscription_status: "active",
        next_payment_date: 1.month.from_now
      )

      flash[:notice] = "Your subscription has been updated to the #{plan_name.titleize} plan."
    else
      Rails.logger.error("Unknown product ID received: #{product_id}")
      flash[:alert] = "There was an issue updating your subscription. Please contact support."
    end
  end
end
