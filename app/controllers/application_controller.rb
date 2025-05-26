class ApplicationController < ActionController::Base
  include Authentication
  before_action :check_plan_limits
  allow_unauthenticated_access if: -> { request.path.start_with?("/jobs") }
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def set_selected_plan(plan)
    if plan.present? && Plan::LIMITS.keys.include?(plan)
      session[:selected_plan] = plan
    end
  end

  def get_selected_plan
    session[:selected_plan] || "free"
  end

  def clear_selected_plan
    session.delete(:selected_plan)
  end

  def require_payment
    return unless authenticated?
    return if Current.user.plan == "free"
    unless Current.user.customer_id
      redirect_to billing_accounts_path, alert: "Please complete your payment."
    end
  end

  def check_confirmed_user
    return unless Current.user
    return if Current.user.confirmed_at?

    flash[:alert] = "Please confirm your email address to unlock all features."
  end

  def check_plan_limits
    return unless authenticated?

    limited_resources = %w[contacts email_templates campaigns]
    limited_resources.each do |resource|
      if action_name == "create" && controller_name == resource.to_s.pluralize
        if Current.user.limit_reached?(resource)
          redirect_to request.referer || dashboard_path, alert: "You've reached your #{resource.to_s.humanize.downcase} limit for your current plan."
          break
        end
      end
    end
  end
end
