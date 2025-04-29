class TrackingController < ApplicationController
  skip_before_action :verify_authenticity_token
  allow_unauthenticated_access
  def open
    campaign = Campaign.find(params[:campaign_id])
    subscriber = Subscriber.find(params[:subscriber_id])

    CampaignEvent.create!(
      campaign: campaign,
      subscriber: subscriber,
      event_type: "open",
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      occurred_at: Time.current
    )

    send_data Base64.decode64("R0lGODlhAQABAAAAACw="), type: "image/gif", disposition: "inline"
  end
end
