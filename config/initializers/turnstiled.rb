Rails.application.config.to_prepare do
  Turnstiled.site_key = Rails.application.credentials.dig(:turnstiled, :site_key)
  Turnstiled.site_secret = Rails.application.credentials.dig(:turnstiled, :site_secret)
end
