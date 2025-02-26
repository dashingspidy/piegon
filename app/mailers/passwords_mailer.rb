class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    attachments.inline["logo-email.png"] = File.read(Rails.root.join("app/assets/images/logo-email.png"))
    mail subject: "Reset your password", to: user.email_address
  end
end
