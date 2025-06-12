class UnsubscribeController < ApplicationController
  allow_unauthenticated_access

  def unsubscribe
    contact_id = params[:contact_id]
    email = params[:email]
    signature = params[:signature]

    expected_signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      Rails.application.secret_key_base,
      "#{contact_id}:#{email}"
    )

    if signature != expected_signature
      render plain: "Invalid signature", status: :forbidden
      return
    end

    subscriber = Subscriber.find_by(contact_id: contact_id, email: email)

    if subscriber
      subscriber.update(unsubscribed: true)
      @contact = subscriber.contact
    else
      render plain: "Subscriber not found", status: :not_found
    end
  end
end
