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
    email_from = params[:email_from]

    if [ "free", "lifetime" ].include?(Current.user.plan)
      mail_setting = Current.user.mail_setting

      unless mail_setting
        redirect_to mail_settings_path, alert: "Please configure your SMTP settings to send emails."
      end
    end

    subscribers = campaign.subscribers

    if Current.user.plan == "free"
      subscribers = subscribers.limit(100)
    end

    subscribers.find_each do |subscriber|
      begin
        if [ "free", "lifetime" ].include?(Current.user.plan) && Current.user.mail_setting.present?
          CampaignMailer.campaign_email(
            subscriber,
            template,
            email_from,
            subject,
            Current.user.mail_setting
          ).deliver_later
        else
          CampaignMailer.campaign_email(
            subscriber,
            template,
            email_from,
            subject
          ).deliver_later
        end

        EmailLog.create!(user: Current.user)

        unless [ "free", "lifetime" ].include?(Current.user.plan)
          email_limit_reached = emails_sent >= (Current.user.email_limit.to_i - emails_sent_this_month)
          break if email_limit_reached
        end
      rescue StandardError => e
        Rails.logger.error("Failed to send email to #{subscriber.email}: #{e.message}")
      end
    end

    redirect_to campaign_subscribers_path(campaign), notice: "Campaign email queued for delivery."
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name)
  end
end
