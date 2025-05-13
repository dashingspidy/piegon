require "uri"
require "net/http"
require "json"

module TurnstileValidatable
  extend ActiveSupport::Concern

  def valid_turnstile_token?
    token = params["cf-turnstile-response"]
    return false if token.blank?

    uri = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    res = Net::HTTP.post_form(uri, {
      secret: Rails.application.credentials.cloudflare_turnstile[:site_secret],
      response: token,
      remoteip: request.remote_ip
    })

    JSON.parse(res.body)["success"] == true
  rescue StandardError => e
    Rails.logger.error("Turnstile verification error: #{e.message}")
    false
  end
end
