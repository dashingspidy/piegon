class ProcessSendgridEventJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(event_data)
    # Extract campaign and subscriber info from event data or unique_args
    campaign_id = event_data["campaign_id"] ||
                  event_data.dig("unique_args", "campaign_id") ||
                  extract_from_smtp_id(event_data["smtp-id"])

    subscriber_id = event_data["subscriber_id"] ||
                    event_data.dig("unique_args", "subscriber_id")

    return unless campaign_id && subscriber_id

    campaign = Campaign.find(campaign_id)
    subscriber = Subscriber.find(subscriber_id)

    # Skip if event already exists (deduplication)
    return if event_data["sg_event_id"] &&
              CampaignEvent.exists?(sendgrid_event_id: event_data["sg_event_id"])

    # Create or update campaign event
    event_attributes = {
      campaign: campaign,
      subscriber: subscriber,
      event_type: normalize_event_type(event_data["event"]),
      sendgrid_event_id: event_data["sg_event_id"],
      timestamp: event_data["timestamp"],
      smtp_id: event_data["smtp-id"],
      occurred_at: Time.at(event_data["timestamp"].to_i),
      unique_args: event_data["unique_args"]
    }

    # Add event-specific data
    case event_data["event"]
    when "bounce", "dropped"
      event_attributes[:reason] = event_data["reason"]
    when "click"
      event_attributes[:url] = event_data["url"]
    when "open"
      event_attributes[:ip_address] = event_data["ip"]
      event_attributes[:user_agent] = event_data["useragent"]
      event_attributes[:email_client] = extract_email_client(event_data["useragent"])
    end

    CampaignEvent.create!(event_attributes)

    Rails.logger.info "Processed SendGrid event: #{event_data['event']} for campaign #{campaign_id}"

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn "Campaign or Subscriber not found for SendGrid event: #{e.message}"
  rescue => e
    Rails.logger.error "Error processing SendGrid event: #{e.message}"
    Rails.logger.error "Event data: #{event_data.inspect}"
    raise e
  end

  private

  def normalize_event_type(sendgrid_event)
    case sendgrid_event
    when "processed" then "processed"
    when "delivered" then "delivered"
    when "open" then "open"
    when "click" then "click"
    when "bounce" then "bounce"
    when "dropped" then "dropped"
    when "deferred" then "deferred"
    when "spamreport" then "spam"
    when "unsubscribe" then "unsubscribe"
    when "group_unsubscribe" then "group_unsubscribe"
    when "group_resubscribe" then "group_resubscribe"
    else sendgrid_event
    end
  end

  def extract_email_client(user_agent)
    return "Unknown" unless user_agent

    case user_agent.downcase
    when /outlook/i then "Outlook"
    when /thunderbird/i then "Thunderbird"
    when /apple mail/i then "Apple Mail"
    when /gmail/i then "Gmail"
    when /yahoo/i then "Yahoo Mail"
    when /mobile/i then "Mobile"
    else "Other"
    end
  end

  def extract_from_smtp_id(smtp_id)
    # If we embed campaign_id in SMTP ID format, extract it here
    # This is a fallback if unique_args don't work
    return nil unless smtp_id

    # Example: if SMTP ID format is "campaign_123_subscriber_456_randomstring"
    match = smtp_id.match(/campaign_(\d+)/)
    match ? match[1] : nil
  end
end
