class CampaignSchedulerJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)

    return if campaign.running? || campaign.finished?

    campaign.update!(running: true)

    BulkCampaignService.send_campaign(campaign)

    campaign.update!(finished: true, running: false)
  end
end
