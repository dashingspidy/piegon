class UnsubscribeController < ApplicationController
  allow_unauthenticated_access

  def unsubscribe
    campaign_id = params[:campaign_id]
    email = params[:email]
    signature = params[:signature]

    expected_signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      Rails.application.credentials.secret_key_base,
      "#{campaign_id}:#{email}"
    )

    if signature != expected_signature
      render plain: "Invalid signature", status: :forbidden
      return
    end

    subscriber = Subscriber.find_by(campaign_id: campaign_id, email: email)

    if subscriber
      subscriber.update(unsubscribed: true)
      @campaign = subscriber.campaign
    else
      render plain: "Subscriber not found", status: :not_found
    end
  end
end
