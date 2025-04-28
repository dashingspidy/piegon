class CampaignEmailJob < ApplicationJob
  queue_as :default
  retry_on Net::SMTPFatalError, Net::SMTPServerBusy, Net::SMTPSyntaxError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(subscriber_id, campaign_id)
    subscriber = Subscriber.find(subscriber_id)
    campaign = Campaign.find(campaign_id)
    CampaignMailer.campaign_email(
      subscriber,
      campaign.email_template,
      campaign.from,
      campaign.header,
      campaign.subject,
      campaign.user.mail_setting
    ).deliver_later
  end
end
