class CampaignSchedulerJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    campaign.update!(running: true)

    # Use bulk service for better rate limiting and performance
    BulkCampaignService.send_campaign(campaign)
  end
end
