class CampaignSchedulerJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    campaign.update!(running: true)
    delivery_time = campaign.send_time_option == "later" ? campaign.send_at : Time.current

    campaign.contact.subscribers.subscribed.find_each do |subscriber|
      CampaignEmailJob.set(wait_until: delivery_time).perform_later(subscriber.id, campaign.id)
    end
  end
end
