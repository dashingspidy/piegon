require "csv"
class SubscribersController < ApplicationController
  allow_unauthenticated_access only: :embed
  skip_before_action :verify_authenticity_token, only: :embed
  include Pagy::Backend
  before_action :set_campaign, except: :embed

  def index
    @pagy, @subscribers = pagy(@campaign.subscribers)
    @csv_upload = CsvUploader.new
    if @campaign.csv_uploader
      @campaign.csv_uploader.csv_file.open do |temp|
        @headers = CSV.foreach(temp, headers: false).first
      end
    end
    @columns = Subscriber.column_names - [ "id", "created_at", "updated_at", "campaign_id" ]
    @api_token = @campaign.api_token
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

  def embed
    @campaign = Campaign.find_by(api_token: params[:api_token])
    @campaign.subscribers.build(subscribers_params)
    if @campaign.save
      render json: { message: "Successfully" }, status: :created
    else
      render json: { error: @campaign.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.subscribers.find(params[:id]).delete
    redirect_to campaign_subscribers_path(@campaign)
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end

  def subscribers_params
    params.require(:subscribers).permit(:email)
  end
end
