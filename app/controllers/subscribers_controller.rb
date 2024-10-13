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
    column_mapping = column_mapping_params
    CsvImportJob.perform_later(@campaign.id, column_mapping)
    redirect_to campaign_subscribers_path(@campaign)
  end

  def new
  end

  def create
  end

  private

  def column_mapping_params
    params.require(:column_mapping).permit!
  end

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end
end
