require "csv"
class CsvImportJob < ApplicationJob
  queue_as :default
  BATCH_SIZE = 1000

  def perform(campaign_id, column_mapping)
    campaign = Campaign.find(campaign_id)
    campaign.csv_uploader.csv_file.open do |temp|
      batch = []
      CSV.foreach(temp, headers: true) do |row|
        mapped_attributes = map_attributes(row, column_mapping)

        batch << mapped_attributes if mapped_attributes.present? && valid_email?(mapped_attributes)
        if batch.size >= BATCH_SIZE
          import_batch(campaign, batch)
          batch = []
        end
      end
      import_batch(campaign, batch) if batch.any?
    end

    campaign.csv_uploader.csv_file.purge_later
    campaign.csv_uploader.destroy
  end

  private

  def map_attributes(row, column_mapping)
    mapped_attributes = {}
    column_mapping.each do |csv_column, subscriber_attribute|
      next if subscriber_attribute == ""
      mapped_attributes[subscriber_attribute] = row[csv_column]
    end
    mapped_attributes
  end

  def valid_email?(email)
    email_regexp = URI::MailTo::EMAIL_REGEXP
    email.match?(email_regexp)
  end

  def import_batch(campaign, batch)
    ActiveRecord::Base.transaction do
      campaign.subscribers.insert_all(batch)
    end
  rescue => e
    Rails.logger.error "Error importing batch: #{e.message}"
  end
end
