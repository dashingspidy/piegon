class SendgridWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  allow_unauthenticated_access

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
end
