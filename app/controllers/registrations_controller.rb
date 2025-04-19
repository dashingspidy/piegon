class RegistrationsController < ApplicationController
  include Payment
  allow_unauthenticated_access(only: [ :new, :create, :confirm ])
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for @user
      @user.send_welcome_email
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
      if @user.confirm! && @user.plan == "free"
      redirect_to dashboard_path, notice: "Your account has been confirmed."
      elsif @user.confirm! && @user.plan != "free"
        redirect_to procced_to_payment_path, notice: "Your account has been confirmed. Proceed to payment."
      else
        redirect_to dashboard_path, alert: "Your account could not be confirmed. Please try again.", status: :unprocessable_entity
      end
    else
      redirect_to dashboard_path, alert: "Invalid confirmation token.", status: :unprocessable_entity
    end
  end

  def procced_to_payment
    @user = Current.user
    selected_plan = params[:plan]

    if selected_plan.present?
      unless Plan::LIMITS.keys.include?(selected_plan)
        redirect_to dashboard_path, alert: "Invalid plan selected."
        return
      end
      @user.update!(plan: selected_plan)
    end

    if @user.plan == "free"
      redirect_to dashboard_path, notice: "You are on free plan."
    end

    payment_url = Payment.create_checkout(@user.plan, @user.email_address)
    respond_to do |format|
      format.html { redirect_to payment_url.to_s, allow_other_host: true }
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :plan)
  end
end
