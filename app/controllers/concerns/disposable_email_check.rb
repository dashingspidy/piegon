# frozen_string_literal: true

require "httparty"

module DisposableEmailCheck
  extend ActiveSupport::Concern

  DISPOSABLE_DOMAINS_URL = "https://raw.githubusercontent.com/disposable/disposable-email-domains/master/domains.json"

  included do
    validate :email_is_not_disposable, if: -> { email_address.present? }
  end

  def disposable_email?
    domain = email_address.to_s.split("@").last&.downcase
    return false if domain.blank?

    disposable_domains.include?(domain)
  end

  private

  def email_is_not_disposable
    error.add(:email_address, "is from a disposable email provider") if disposable_email?
  end

  def disposable_domains
    Rails.cache.fetch("disposable_email_domains", expires_in: 1.day) do
      response = HTTParty.get(DISPOSABLE_DOMAINS_URL, timeout: 10)
      JSON.parse(response.body) if response.success?
    rescue StandardError => e
      Rails.logger.error "Error getting disposable domains: #{e.message}"
      []
    end
  end
end
