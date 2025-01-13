class AccountsController < ApplicationController
  include Payment
  def index
    @products = PRODUCTS.reject { |plan, _| plan == "lifetime" }
  end

  def update_password
    if Current.user.authenticate(params[:current_password])
      if params[:password] == params[:password_confirmation]
        if Current.user.update(password: params[:password])
          reset_session
          flash[:notice] = "Password updated successfully. Please login with your new password."
          redirect_to new_session_path
        else
          flash[:alert] = "Unable to update password. Please try again."
          redirect_to accounts_path
        end
      else
        flash[:alert] = "New password and confirmation do not match"
        redirect_to accounts_path
      end
    else
      flash[:alert] = "Current password is incorrect"
      redirect_to accounts_path
    end
  end

  def cancel_subscription
    subs_id = Current.user.subscription_id
    Payment.cancel_subscription(subs_id)
    redirect_to accounts_path, notice: "Subscription canceled."
  end

  def create
    @plan = params[:plan]
    if @plan == Current.user.plan
      flash[:alert] = "You are already on this plan"
      redirect_to accounts_path
    end

    begin
      checkout_url = Payment.create_update_checkout(@plan)
      respond_to do |format|
        format.html { redirect_to checkout_url.to_s, allow_other_host: true }
      end
    rescue => e
      Rails.logger.error("Subscription update failed: #{e.message}")
      flash[:alert] = "Unable to process plan update. Please try again later."
      redirect_to dashboard_path
    end
  end

  def destroy
    Current.user.destroy
    redirect_to root_path, notice: "Your account has been deleted."
  end
end
