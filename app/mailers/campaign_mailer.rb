class CampaignMailer < ApplicationMailer
  def campaign_email(subscriber, email_template, email_from, email_subject, mail_setting = nil)
    @subscriber = subscriber
    @email_subject = email_subject
    @rendered_body = render_template(email_template.body)
    @email_from = email_from

    mail_options = {
      to: @subscriber.email,
      subject: @email_subject
    }

    if mail_setting
      mail_options[:from] = @email_from
      mail_options[:delivery_method_options] = mail_setting.to_smtp_settings
    else
      mail_options[:from] = @email_from
    end

    mail(mail_options)
  end

  private

  def render_template(body)
    ERB.new(body).result(binding)
  end
end
