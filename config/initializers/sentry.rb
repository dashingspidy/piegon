# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = "https://164d21e0764e61b3caa2e64da6c5689b@o4509603504848896.ingest.de.sentry.io/4509603506421840"
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Add data like request headers and IP for users,
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true
end
