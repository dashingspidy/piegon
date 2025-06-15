class CampaignsController < ApplicationController
  before_action :check_confirmed_user, only: %i[new create]
  before_action :require_payment, only: %i[new create]
  before_action :set_contact_and_template, only: %i[new create edit]
  before_action :set_campaign, only: %i[show edit update destroy]
  def index
    @campaigns = Current.user.campaigns
  end

  def show
    # Core metrics
    @total_sent = @campaign.total_sent
    @total_processed = @campaign.total_processed
    @total_delivered = @campaign.total_delivered
    @total_opened = @campaign.total_opened
    @total_clicked = @campaign.total_clicked
    @total_bounced = @campaign.total_bounced
    @total_dropped = @campaign.total_dropped
    @total_spam_reports = @campaign.total_spam_reports
    @total_unsubscribed = @campaign.total_unsubscribed

    # Rate calculations
    @delivery_rate = @campaign.delivery_rate
    @open_rate = @campaign.open_rate
    @click_rate = @campaign.click_rate
    @click_to_open_rate = @campaign.click_to_open_rate
    @bounce_rate = @campaign.bounce_rate
    @spam_rate = @campaign.spam_rate
    @unsubscribe_rate = @campaign.unsubscribe_rate

    # Legacy compatibility
    @open_percentage = @campaign.open_percentage
    @bounce_percentage = @campaign.bounce_percentage

    # Distribution analytics
    @country_distribution = @campaign.country_distribution
    @device_distribution = @campaign.device_distribution
    @email_client_distribution = @campaign.email_client_distribution
    @click_url_distribution = @campaign.click_url_distribution
    @bounce_reason_distribution = @campaign.bounce_reason_distribution

    # Time-based analytics
    @hourly_engagement = @campaign.hourly_engagement
    @daily_activity = @campaign.daily_activity
  end

  def new
    @campaign = Current.user.campaigns.new
  end

  def create
    @campaign = Current.user.campaigns.build(campaign_params)
    @campaign.send_time_option = params[:campaign][:send_time_option]

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
      unless @campaign.running? || @campaign.finished?
        schedule_campaign_emails(@campaign)
      end
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
    params.require(:campaign).permit(:name, :subject, :header, :from, :contact_id, :email_template_id, :send_at, :domain_verification_id, :send_time_option)
  end

  def set_contact_and_template
    @contacts = Current.user.contacts
    @templates = Current.user.email_templates
  end

  def set_campaign
    @campaign = Current.user.campaigns.find(params[:id])
  end

  def schedule_campaign_emails(campaign)
    if campaign.send_at <= Time.current
      CampaignSchedulerJob.perform_later(campaign.id)
    else
      CampaignSchedulerJob.set(wait_until: campaign.send_at).perform_later(campaign.id)
    end
  end
end
