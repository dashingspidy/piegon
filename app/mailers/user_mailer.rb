class UserMailer < ApplicationMailer
  def confirmation_instructions(user)
    @user = user
    @confirmation_url = confirm_registration_url(token: @user.confirmation_token)

    mail(to: @user.email_address, subject: "Confirm your account")
  end

  def welcome(user)
    @user = user

    mail(to: @user.email_address, subject: "Welcome to Piegon")
  end
end
