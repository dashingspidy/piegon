require "csv"
class SubscribersController < ApplicationController
  include Pagy::Backend
  before_action :set_campaign

  def index
    @pagy, @subscribers = pagy(@campaign.subscribers)
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
    column_mapping = params["column_mapping"].to_unsafe_h
    if column_mapping.present?
      CsvImportJob.perform_later(@campaign.id, column_mapping)
      redirect_to campaign_subscribers_path(@campaign), notice: "CSV import started."
    else
      redirect_to campaign_subscribers_path(@campaign), alert: "No column mapping. Try"
    end
  end

  def new
  end

  def create
  end

  def destroy
    @campaign.subscribers.find(params[:id]).delete
    redirect_to campaign_subscribers_path(@campaign)
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end
end
