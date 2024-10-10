require "csv"
class SubscribersController < ApplicationController
  before_action :set_campaign

  def index
    @csv_upload = CsvUploader.new
    if @campaign.csv_uploader
      @campaign.csv_uploader.csv_file.open do |temp|
        @headers = CSV.foreach(temp, headers: false).first
      end
    end
    @columns = Subscriber.column_names - [ "id", "created_at", "updated_at", "campaign_id" ]
  end

  def upload
    @csv_upload = @campaign.build_csv_uploader(params.require(:csv_uploader).permit(:csv_file))
    if @csv_upload.save
      redirect_to campaign_subscribers_path(@campaign), notice: "Upload successful"
    else
      render campaign_subscribers_path(@campign)
    end
  end

  def parse_csv
    column_mapping = params["column_mapping"]
    @campaign.csv_uploader.csv_file.open do |temp|
      CSV.foreach(temp, headers: true) do |row|
        mapped_attributes = {}
        column_mapping.each do |csv_column, subscriber_attribute|
          next if subscriber_attribute == ""
          mapped_attributes[subscriber_attribute] = row[csv_column]
        end
        @campaign.subscribers.create(mapped_attributes) unless mapped_attributes.empty?
      end
    end
    @campaign.csv_uploader.csv_file.purge_later
    @campaign.csv_uploader.delete
    redirect_to campaign_subscribers_path(@campaign)
  end

  def new
  end

  def create
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end
end
