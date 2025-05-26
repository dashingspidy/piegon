class OauthController < ApplicationController
  allow_unauthenticated_access

  def google
    auth = request.env["omniauth.auth"]

    selected_plan = get_selected_plan
    user = User.from_omniauth(auth, selected_plan)

    if user.persisted?
      clear_selected_plan
      start_new_session_for user
      if user.created_at > 1.minute.ago
        redirect_to after_authentication_url, notice: "Welcome to Piegon! Your account has been created with the #{selected_plan} plan."
      else
        redirect_to after_authentication_url, notice: "Successfully signed in with Google!"
      end
    else
      redirect_to new_registration_url, alert: "There was an error signing you in with Google. Please try again."
    end
  end

  def failure
    redirect_to new_registration_url, alert: "Authentication failed. Please try again."
  end
end
