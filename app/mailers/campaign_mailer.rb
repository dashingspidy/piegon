class CampaignMailer < ApplicationMailer
  def campaign_email(subscriber, email_template, email_subject)
    @subscriber = subscriber
    @email_subject = email_subject
    @rendered_body = render_template(email_template.body)
    mail(
      to: @subscriber.email,
      subject: @subject,
      from: "no-reply@piegon.pro"
    )
  end

  private

  def render_template(body)
    ERB.new(body).result(binding)
  end
end
