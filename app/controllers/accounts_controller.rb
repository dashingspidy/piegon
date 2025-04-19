class AccountsController < ApplicationController
  include Payment
  def profile
  end

  def billing
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
  end

  def destroy
    Current.user.destroy
    redirect_to root_path, notice: "Your account has been deleted."
  end
end
