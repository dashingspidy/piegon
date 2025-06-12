class BulkCampaignService
  BATCH_SIZE = 100 # Smaller batches for SMTP to avoid timeouts
  DELAY_BETWEEN_BATCHES = 10.seconds # Rate limiting

  def self.send_campaign(campaign)
    new(campaign).send_all
  end

  def initialize(campaign)
    @campaign = campaign
  end

  def send_all
    subscribers = @campaign.contact.subscribers.subscribed
    total_batches = (subscribers.count.to_f / BATCH_SIZE).ceil

    Rails.logger.info "Starting campaign #{@campaign.id} - #{subscribers.count} subscribers in #{total_batches} batches"

    subscribers.in_batches(of: BATCH_SIZE).each.with_index do |batch, index|
      delay = index * DELAY_BETWEEN_BATCHES

      batch.each do |subscriber|
        CampaignEmailJob.set(wait: delay).perform_later(subscriber.id, @campaign.id)
      end

      Rails.logger.info "Queued batch #{index + 1}/#{total_batches} for campaign #{@campaign.id}"
    end
  end
end
