class AccountsController < ApplicationController
  include Payment
  skip_before_action :verify_authenticity_token, only: :webhook
  def profile
  end

  def billing
  end

  def customer_portal
    customer_id = Current.user.customer_id
    if customer_id.present?
      portal_url = Payment.customer_portal(customer_id)
      respond_to do |format|
        format.html { redirect_to portal_url.to_s, allow_other_host: true }
      end
    else
      flash[:alert] = "Customer ID not found."
      redirect_to billing_accounts_path
    end
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

  def webhook
    payload = JSON.parse(request.body.read)
    event_type = payload["eventType"]
    customer_id = payload.dig("object", "customer", "id")

    if event_type == "refund.created" && customer_id.present?
      user = User.find_by(customer_id: customer_id)

      if user
        user.update!(plan: "free")
        redirect_to dashboard_path, warning: "You have been downgraded to the free plan due to refund."
      end
    end
  end
  def destroy
    Current.user.destroy
    redirect_to root_path, notice: "Your account has been deleted."
  end
end
