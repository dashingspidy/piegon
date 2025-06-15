class SendgridWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  allow_unauthenticated_access

  before_action :capture_raw_body
  before_action :verify_webhook_signature

  attr_reader :raw_body

  def webhook
    # Parse the events from the request body
    events = params["_json"] || JSON.parse(request.body.read)

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

  def capture_raw_body
    @raw_body = request.body.read
    request.body.rewind
  end

  def verify_webhook_signature
    return if Rails.env.development? # Skip verification in development

    # Get the verification key from SendGrid
    verification_key = Rails.application.credentials.dig(:sendgrid, :webhook_verification_key)
    unless verification_key
      Rails.logger.error "SendGrid webhook verification key not found in credentials"
      return head :unauthorized
    end

    signature = request.headers["X-Twilio-Email-Event-Webhook-Signature"]
    timestamp = request.headers["X-Twilio-Email-Event-Webhook-Timestamp"]

    unless signature && timestamp
      Rails.logger.warn "SendGrid webhook missing signature or timestamp headers"
      return head :unauthorized
    end

    # Use the captured raw body for signature verification
    payload = @raw_body
    if payload.blank?
      Rails.logger.warn "SendGrid webhook empty payload"
      return head :unauthorized
    end

    # Verify the signature using SendGrid's algorithm
    begin
      expected_signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest("sha256", verification_key, timestamp + payload)
      )

      unless Rack::Utils.secure_compare(signature, expected_signature)
        Rails.logger.warn "SendGrid webhook signature verification failed"
        Rails.logger.debug "Expected: #{expected_signature}"
        Rails.logger.debug "Received: #{signature}"
        Rails.logger.debug "Timestamp: #{timestamp}"
        Rails.logger.debug "Payload length: #{payload.length}"
        return head :unauthorized
      end

      Rails.logger.info "SendGrid webhook signature verified successfully"
    rescue => e
      Rails.logger.error "SendGrid webhook signature verification error: #{e.message}"
      head :unauthorized
    end
  end
end
