class CampaignMailer < ApplicationMailer
  layout false
  skip_before_action :attach_logo

  def campaign_email(subscriber, email_template, email_from, email_header, email_subject, mail_setting)
    @subscriber = subscriber
    @rendered_body = render_template(email_template.body)
    @unsubscribe_url = generate_unsubscribe_url(subscriber)

    mail_options = {
      to: @subscriber.email,
      subject: email_subject
    }

    if mail_setting
      mail_options[:from] = "#{email_header} <#{email_from}>"
      mail_options[:delivery_method_options] = mail_setting.to_smtp_settings
    end

    mail(mail_options)
  end

  private

  def render_template(body)
    ERB.new(body).result(binding)
  end

  def generate_unsubscribe_url(subscriber)
    signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      Rails.application.credentials.secret_key_base,
      "#{subscriber.contact_id}:#{subscriber.email}"
    )

    unsubscribe_url(
      contact_id: subscriber.contact_id,
      email: subscriber.email,
      signature: signature
    )
  end
end
