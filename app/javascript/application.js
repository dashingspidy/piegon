// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "chartkick/chart.js"
import "./controllers"

import "trix"
import "@rails/actiontext"

// Sentry error tracking and feedback
import * as Sentry from "@sentry/browser";

Sentry.init({
  dsn: "https://164d21e0764e61b3caa2e64da6c5689b@o4509603504848896.ingest.de.sentry.io/4509603506421840",
  // Setting this option to true will send default PII data to Sentry.
  // For example, automatic IP address collection on events
  sendDefaultPii: true,
  integrations: [
    Sentry.feedbackIntegration({
      colorScheme: "system",
      isNameRequired: true,
      isEmailRequired: true,
    }),
  ]
});

// Make Sentry available globally for Rails error reporting
window.Sentry = Sentry;
