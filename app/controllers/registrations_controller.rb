class RegistrationsController < ApplicationController
  include TurnstileValidatable

  rate_limit to: 4, within: 1.minute, only: :create
  allow_unauthenticated_access(only: [ :new, :create, :confirm ])
  def new
    @user = User.new
    set_selected_plan(params[:plan])
  end

  def create
    @user = User.new(user_params)

    plan_to_use = get_selected_plan
    if params.dig(:user, :plan).present? && Plan::LIMITS.keys.include?(params.dig(:user, :plan))
      plan_to_use = params.dig(:user, :plan)
    end
    @user.plan = plan_to_use

    unless valid_turnstile_token?
      @user.errors.add(:turnstile, "Please complete the security check")
      return render :new, status: :unprocessable_entity
    end

    if @user.save
      clear_selected_plan
      start_new_session_for @user
      @user.send_confirmation_instructions
      redirect_to dashboard_path, notice: "Welcome to Piegon! Confirm your email address to continue further."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def resend_confirmation
    Current.user.send_confirmation_instructions
    redirect_to dashboard_path, notice: "Confirmation instructions have been resent to your email."
  end

  def confirm
    @user = User.find_by(confirmation_token: params[:token])

    if @user
      if @user.confirm!
        redirect_to dashboard_path, notice: "Your account has been confirmed."
      else
        redirect_to dashboard_path, alert: "Your account could not be confirmed. Please try again.", status: :unprocessable_entity
      end
    else
      redirect_to dashboard_path, alert: "Invalid confirmation token.", status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :plan)
  end
end
