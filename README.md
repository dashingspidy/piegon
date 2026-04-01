# Piegon

Piegon is a Rails 8 email marketing application with contact lists, embeddable subscriber capture, email templates, campaign sending, analytics, domain verification, ticketing, and article generation.

This repository is the open-source version of an older internal project. Payment and checkout integrations have been removed. Some optional third-party features still require you to provide your own credentials.

## Stack

- Ruby on Rails 8
- SQLite for local development
- Hotwire
- Tailwind CSS
- Solid Queue / Solid Cache / Solid Cable
- SendGrid for outbound email and event webhooks
- Google OAuth for sign-in
- Cloudflare Turnstile for signup protection
- Stripo for the drag-and-drop email editor
- OpenAI for article generation

## Requirements

- Ruby `3.3+`
- Bundler
- Node.js `20+`
- Yarn
- SQLite

## Setup

1. Install dependencies:

```bash
bundle install
yarn install
```

2. Create and migrate the database:

```bash
bin/rails db:prepare
```

3. Add credentials for any integrations you want to use.

This app reads secrets from Rails credentials. Create your own credentials locally:

```bash
bin/rails credentials:edit
```

Example credential structure:

```yml
google:
  client_id: your-google-client-id
  client_secret: your-google-client-secret

sendgrid:
  api_key: your-sendgrid-api-key

cloudflare_turnstile:
  site_key: your-turnstile-site-key
  site_secret: your-turnstile-site-secret

stripo:
  secret_key: your-stripo-secret-key

openai:
  api_key: your-openai-api-key

cloudflare:
  access_key_id: your-r2-access-key-id
  secret_access_key: your-r2-secret-access-key
```

4. Start the app:

```bash
bin/dev
```

Then open `http://localhost:3000`.

## Main Features

- User registration, confirmation, password reset, and Google OAuth
- Contact lists and CSV subscriber import
- Embeddable subscriber widget per contact list
- Email templates, including a Stripo-powered drag-and-drop editor
- Campaign creation, scheduling, and SendGrid event ingestion
- Domain verification
- Ticketing/help area
- AI-assisted article generation

## Optional Integrations

You can run the core app without every integration, but related features will not work until configured.

- `sendgrid.api_key`
  Required for application email delivery and campaign sending.
- `google.client_id` and `google.client_secret`
  Required for Google OAuth sign-in.
- `cloudflare_turnstile.site_key` and `cloudflare_turnstile.site_secret`
  Required for registration bot protection.
- `stripo.secret_key`
  Required for the `/token` endpoint used by the drag-and-drop email editor.
- `openai.api_key`
  Required for article generation tasks and services.
- `cloudflare.access_key_id` and `cloudflare.secret_access_key`
  Required only if you use the configured Cloudflare/R2 storage backend.

## Email and Webhooks

The app expects SendGrid in several places:

- Action Mailer SMTP delivery
- campaign delivery services
- event webhook ingestion at `POST /sendgrid/webhook`

For local development you can disable or stub email delivery, or supply a test SendGrid key.

## Development Notes

- `.env*`, `config/master.key`, and credential key files are gitignored.
- Rails encrypted credential files in `config/credentials/*.yml.enc` are safe to commit; the matching key files are not.
- Billing code and checkout routes were intentionally removed from this public version.

## Useful Commands

```bash
bin/dev
bin/rails db:prepare
bin/rails test
bin/rubocop
bin/brakeman
```

## Open Source Hardening Checklist

- Add your own credentials before enabling external integrations.
- Review deployment config in `config/deploy.yml` and `.kamal/` before using it.
- Rotate any credentials that were ever used with the private version of this app.
- Audit copy, branding, privacy policy, and terms before public deployment.
