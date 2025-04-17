class AccountsController < ApplicationController
  include Payment
  def profile
  end

  def billing
    @products = PRODUCTS
  end

  def update_password
    unless Current.user.authenticate(params[:current_password])
      flash[:alert] = "Current password is incorrect"
      return redirect_to profile_accounts_path
    end

    unless params[:password] == params[:password_confirmation]
      flash[:alert] = "New password and confirmation do not match"
      return redirect_to profile_accounts_path
    end

    if Current.user.update(password: params[:password])
      reset_session
      flash[:notice] = "Password updated successfully. Please login with your new password."
      redirect_to new_session_path
    else
      flash[:alert] = "Unable to update password. Please try again."
      redirect_to profile_accounts_path
    end
  end

  def create
    @plan = params[:plan]
    if @plan == Current.user.plan
      flash[:alert] = "You are already on this plan"
      redirect_to billing_accounts_path
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
