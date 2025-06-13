class SendgridWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  allow_unauthenticated_access

  before_action :verify_webhook_signature

  def webhook
    events = JSON.parse(request.body.read)

    events.each do |event|
      ProcessSendgridEventJob.perform_later(event)
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "SendGrid webhook JSON parse error: #{e.message}"
    head :bad_request
  rescue => e
    Rails.logger.error "SendGrid webhook error: #{e.message}"
    head :internal_server_error
  end

  private

  def verify_webhook_signature
    return if Rails.env.development? # Skip verification in development

    # Get the verification key from SendGrid (you'll need to set this in credentials)
    verification_key = Rails.application.credentials.dig(:sendgrid, :webhook_verification_key)
    return head :unauthorized unless verification_key

    signature = request.headers["X-Twilio-Email-Event-Webhook-Signature"]
    timestamp = request.headers["X-Twilio-Email-Event-Webhook-Timestamp"]

    return head :unauthorized unless signature && timestamp

    # Verify the signature
    payload = request.raw_post
    expected_signature = Base64.strict_encode64(
      OpenSSL::HMAC.digest("sha256", verification_key, timestamp + payload)
    )

    unless Rack::Utils.secure_compare(signature, expected_signature)
      Rails.logger.warn "SendGrid webhook signature verification failed"
      head :unauthorized
    end
  end
end
