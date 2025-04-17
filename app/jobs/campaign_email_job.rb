class CampaignEmailJob < ApplicationJob
  queue_as :default

  def perform(subscriber_id, campaign_id)
    subscriber = Subscriber.find(subscriber_id)
    campaign = Campaign.find(campaign_id)
    CampaignMailer.campaign_email(
      subscriber,
      campaign.email_template,
      campaign.from,
      campaign.header,
      campaign.subject,
      campaign.mail_setting
    ).deliver_now
  end
end
