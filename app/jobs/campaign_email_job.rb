class CampaignEmailJob < ApplicationJob
  queue_as :default
  retry_on Net::SMTPFatalError, Net::SMTPServerBusy, Net::SMTPSyntaxError, wait: ->(executions) { executions * 2 }, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(subscriber_id, campaign_id)
    subscriber = Subscriber.find(subscriber_id)
    campaign = Campaign.find(campaign_id)

    # Simplified call - no more mail_setting dependency
    CampaignMailer.campaign_email(subscriber, campaign).deliver_now

    CampaignEvent.create!(
      campaign: campaign,
      subscriber: subscriber,
      event_type: "send"
    )

    total_recipients = campaign.contact.subscribers.subscribed.count
    total_sent = campaign.campaign_events.where(event_type: "send").distinct.count(:subscriber_id)

    if total_sent >= total_recipients
      campaign.update!(finished: true, running: false)
    end
  end
end
