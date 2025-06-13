class AccountsController < ApplicationController
  include Payment
  skip_before_action :verify_authenticity_token, only: :webhook
  def profile
  end

  def billing
    @email_usage = {
      sent: Current.user.emails_sent,
      limit: Current.user.email_limit,
      additional: Current.user.additional_emails,
      total_available: Current.user.total_available_emails,
      remaining: Current.user.emails_remaining,
      usage_percentage: Current.user.email_usage_percentage
    }
    @email_credit_packages = Payment.email_credit_packages
  end

  def purchase_email_credits
    units = params[:units].to_i
    product_name = "10000" # Using the 10000 email credits product

    if units <= 0
      redirect_to billing_accounts_path, alert: "Please enter a valid number of units."
      return
    end

    payment_url = Payment.create_seat_based_checkout(product_name, Current.user.email_address, units)

    if payment_url
      respond_to do |format|
        format.html { redirect_to payment_url.to_s, allow_other_host: true }
      end
    else
      redirect_to billing_accounts_path, alert: "Unable to create checkout. Please try again."
    end
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
    product_id = payload.dig("object", "product", "id")
    units = payload.dig("object", "units")

    if event_type == "refund.created" && customer_id.present?
      user = User.find_by(customer_id: customer_id)

      if user
        user.update!(plan: "free")
        redirect_to dashboard_path, warning: "You have been downgraded to the free plan due to refund."
      end
    elsif event_type == "payment.created" && customer_id.present?
      user = User.find_by(customer_id: customer_id)

      if user && product_id.present?
        # Check if this is the email credits product (10000)
        email_credits_product = Payment::PRODUCTS["10000"]

        if email_credits_product && product_id == email_credits_product[:id]
          if units.present?
            # Seat-based purchase: units * credits per unit
            credits_per_unit = email_credits_product[:credits]
            total_credits = units.to_i * credits_per_unit
            user.purchase_additional_emails!(total_credits)
            Rails.logger.info "Added #{total_credits} email credits (#{units} units) to user #{user.id}"
          else
            # Regular purchase: just the base credits
            credits_to_add = email_credits_product[:credits]
            user.purchase_additional_emails!(credits_to_add)
            Rails.logger.info "Added #{credits_to_add} email credits to user #{user.id}"
          end
        else
          # Check if this is a plan upgrade (echo or thunder)
          plan_product = Payment::PRODUCTS.find { |plan_name, product| product[:id] == product_id && [ "echo", "thunder" ].include?(plan_name) }

          if plan_product
            plan_name = plan_product[0]
            user.update!(plan: plan_name, customer_id: customer_id)
            Rails.logger.info "Upgraded user #{user.id} to #{plan_name} plan"
          end
        end
      end
    end
  end

  def destroy
    Current.user.destroy
    redirect_to root_path, notice: "Your account has been deleted."
  end
end
