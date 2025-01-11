class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for @user
      # @user.send_confirmation_instructions
      if @user.plan != "free"
        payment_url = Payment.create_checkout(@user.plan, @user.email_address)
        respond_to do |format|
          format.html { redirect_to payment_url.to_s, allow_other_host: true }
        end
      else
        redirect_to dashboard_path, notice: "Welcome to Piegon!"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def confirm
    @user = User.find_by(confirmation_token: params[:token])

    if @user
      @user.confirm!
      redirect_to dashboard_path, notice: "Your account has been confirmed. Welcome!"
    else
      redirect_to dashboard_path, alert: "Invalid confirmation token.", status: :unprocessable_entity
    end
  end


  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :plan)
  end
end
