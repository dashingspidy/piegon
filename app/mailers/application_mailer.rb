class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@piegon.pro"
  layout "mailer"

  before_action :attach_logo

  private

  def attach_logo
    attachments.inline["logo-email.png"] = File.read(Rails.root.join("app/assets/images/logo-email.png"))
  end
end
