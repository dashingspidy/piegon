require "csv"
class CsvImportJob < ApplicationJob
  queue_as :default
  BATCH_SIZE = 1000

  def perform(campaign_id, column_mapping)
    @campaign = Campaign.find(campaign_id)
    @existing_emails = Set.new(@campaign.subscribers.pluck(:email))
    @duplicates = []
    @processed = 0
    @imported = 0

    @campaign.csv_uploader.csv_file.open do |temp|
      batch = []
      CSV.foreach(temp, headers: true) do |row|
        @processed += 1
        mapped_attributes = map_attributes(row, column_mapping)
        if should_import?(mapped_attributes)
          batch << mapped_attributes
          @existing_emails.add(mapped_attributes["email"])
          @imported += 1
        end

        if batch.size >= BATCH_SIZE
          import_batch(@campaign, batch)
          batch = []
        end
      end
      import_batch(@campaign, batch) if batch.any?
    end
    log_import_results
    cleanup_resources
  end

  private

  def map_attributes(row, column_mapping)
    mapped_attributes = {}
    column_mapping.each do |csv_column, subscriber_attribute|
      next if subscriber_attribute.blank?
      mapped_attributes[subscriber_attribute] = row[csv_column]
    end
    mapped_attributes
  end

  def should_import?(attributes)
    return false unless valid_email?(attributes)
    email = attributes["email"].downcase
    if @existing_emails.include?(email)
      @duplicates << email
      return false
    end
    true
  end

  def valid_email?(attributes)
    email_regexp = URI::MailTo::EMAIL_REGEXP
    return false unless attributes["email"]
    attributes["email"].match?(email_regexp)
  end

  def import_batch(campaign, batch)
    ActiveRecord::Base.transaction do
      campaign.subscribers.insert_all(batch)
    end
  rescue => e
    Rails.logger.error "Error importing batch: #{e.message}"
    notify_admin_of_error(e)
  end

  def log_import_results
    message = <<~MSG
      CSV Import completed:
      - Total processed: #{@processed}
      - Successfully imported: #{@imported}
      - Duplicates found: #{@duplicates.size}
      - Invalid/skipped: #{@processed - @imported - @duplicates.size}
    MSG

    Rails.logger.info(message)
    notify_user_of_completion(message)
  end

  def cleanup_resources
    @campaign.csv_uploader.csv_file.purge_later
    @campaign.csv_uploader.destroy
  end

  def notify_user_of_completion(message)
    # You can implement this based on your notification system
    # For example:
    # UserMailer.csv_import_completed(@campaign.user, message).deliver_later
  end

  def notify_admin_of_error(error)
    # You can implement this based on your error notification system
    # For example:
    # AdminMailer.csv_import_error(@campaign, error).deliver_later
    # or
    # Sentry.capture_exception(error)
  end
end
