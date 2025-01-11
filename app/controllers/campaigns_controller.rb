class CampaignsController < ApplicationController
  include Payment
  before_action :check_email_limit, only: [ :send_campaign, :prepare_campaign ]
  def index
    @campaigns = Current.user.campaigns
  end

  def new
    @campaign = Current.user.campaigns.new
  end

  def create
    @campaign = Current.user.campaigns.build(campaign_params)
    if @campaign.save
      redirect_to campaigns_path, notice: "New campaign created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def prepare_campaign
    @campaign = Campaign.find(params[:id])
    @email_templates = EmailTemplate.where(user_id: Current.user)
  end

  def send_campaign
    campaign = Campaign.find(params[:id])
    template = EmailTemplate.find(params[:template_id])
    subject = params[:subject]

    campaign.subscribers.find_each do |subscriber|
      CampaignMailer.campaign_email(subscriber, template, subject).deliver_later
      EmailLog.create!(user: Current.user)
    rescue StandardError => e
      Rails.logger.error("Failed to send email to #{subscriber.email}: #{e.message}")
    end

    redirect_to campaign_subscribers_path(campaign), notice: "Campaign email queued for delivery"
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name)
  end
end
