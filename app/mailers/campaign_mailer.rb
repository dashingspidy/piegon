class CampaignMailer < ApplicationMailer
  layout false
  skip_before_action :attach_logo

  def campaign_email(subscriber, campaign)
    @subscriber = subscriber
    @campaign = campaign
    @rendered_body = render_template(campaign.email_template.body)
    @unsubscribe_url = generate_unsubscribe_url(subscriber)

    # Add SendGrid tracking headers and unique args
    headers["X-SMTPAPI"] = {
      unique_args: {
        campaign_id: campaign.id.to_s,
        subscriber_id: subscriber.id.to_s,
        user_id: campaign.user.id.to_s
      },
      category: [ "campaign_#{campaign.id}", "user_#{campaign.user.id}" ],
      filters: {
        clicktrack: { settings: { enable: 1 } },
        opentrack: { settings: { enable: 1 } }
      }
    }.to_json

    mail(
      to: @subscriber.email,
      subject: campaign.subject,
      from: campaign.full_from_address
    )
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
      Rails.application.secret_key_base,
      "#{subscriber.contact_id}:#{subscriber.email}"
    )

    unsubscribe_url(
      contact_id: subscriber.contact_id,
      email: subscriber.email,
      signature: signature
    )
  end
end
