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
    email_send_in_batch = 0

    if [ "free", "lifetime" ].include?(Current.user.plan)
      mail_setting = Current.user.mail_setting

      unless mail_setting
        redirect_to mail_settings_path, alert: "Please configure your SMTP settings to send emails."
      end
    end

    if ![ "free", "lifetime" ].include?(Current.user.plan) &&
      Current.user.subscription_status != "active"
     redirect_to accounts_path, alert: "Your subscription is not active. Please update your payment information."
     return
    end

    subscribers = campaign.subscribers.subscribed

    if Current.user.plan == "free"
      subscribers = subscribers.limit(100)
    end

    max_emails_for_batch = Current.user.plan == "free" ? 100 :
                          (Current.user.plan == "lifetime" ? Float::INFINITY :
                          [ remaining_emails, subscribers.count ].min)

    subscribers.find_each do |subscriber|
      break if emails_sent_in_batch >= max_emails_for_batch

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

        Current.user.email_logs.create!
        Current.user.increment!(:emails_used)
        email_send_in_batch += 1

      rescue StandardError => e
        Rails.logger.error("Failed to send email to #{subscriber.email}: #{e.message}")
      end
    end

    notice_message = "Campaign email queued for delivery to #{emails_sent_in_batch} subscribers."

    if emails_sent_in_batch < subscribers.count
      notice_message += " Some subscribers were skipped due to your plan limits."
    end

    redirect_to campaign_subscribers_path(campaign), notice: notice_message
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name)
  end
end
