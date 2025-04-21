class CampaignsController < ApplicationController
  before_action :check_confirmed_user, only: %i[new create]
  before_action :require_payment, only: %i[new create]
  before_action :set_contact_and_template, only: %i[new create edit]
  before_action :set_campaign, only: %i[show edit update destroy]
  def index
    @campaigns = Current.user.campaigns
  end

  def show
  end

  def new
    @campaign = Current.user.campaigns.new
  end

  def create
    @campaign = Current.user.campaigns.build(campaign_params)
    @campaign.send_time_option = params[:campaign][:send_time_option]
    if @campaign.send_time_option == "now"
      @campaign.send_at = Time.current
      @campaign.running = true
    end

    if @campaign.save
      schedule_campaign_emails(@campaign)
      redirect_to campaigns_path, notice: "Campaign created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @campaign.send_time_option = params[:campaign][:send_time_option]

    if @campaign.send_time_option == "now"
      @campaign.send_at = Time.current
    end

    if @campaign.update(campaign_params)
      redirect_to campaigns_path, notice: "Campaign updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.destroy
    redirect_to campaigns_path, notice: "Campaign deleted successfully."
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name, :subject, :header, :from, :contact_id, :email_template_id, :send_at)
  end

  def set_contact_and_template
    @contacts = Current.user.contacts
    @templates = Current.user.email_templates
  end

  def set_campaign
    @campaign = Current.user.campaigns.find(params[:id])
  end

  def schedule_campaign_emails(campaign)
    delivery_time = campaign.send_time_option == "later" ? campaign.send_at : Time.current

    campaign.contact.subscribers.find_each do |subscriber|
      job = CampaignEmailJob.set(wait_until: delivery_time)
      job.perform_later(subscriber.id, campaign.id)
    end
  end
end
