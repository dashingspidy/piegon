class CampaignMailer < ApplicationMailer
  layout false
  skip_before_action :attach_logo

  def campaign_email(subscriber, email_template, email_from, email_header, email_subject, mail_setting, campaign)
    @subscriber = subscriber
    @campaign = campaign
    @rendered_body = render_template(email_template.body)
    @unsubscribe_url = generate_unsubscribe_url(subscriber)
    @tracking_pixel_url = Rails.application.routes.url_helpers.tracking_pixel_url(
      campaign_id: @campaign.id,
      subscriber_id: @subscriber.id,
      host: default_url_options[:host]
    )

    mail_options = {
      to: @subscriber.email,
      subject: email_subject,
      from: "#{email_header} <#{email_from}>",
      delivery_method: :smtp,
      delivery_method_options: mail_setting.to_smtp_settings
    }

    mail(mail_options)
  end

  private

  def render_template(body)
    if body.is_a?(ActionText::RichText)
      body.to_s
    else
      ERB.new(body.to_s).result(binding)
    end
  rescue => e
    Rails.logger.error("Error rendering email template: #{e.message}")
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
