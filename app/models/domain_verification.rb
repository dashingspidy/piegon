class DomainVerification < ApplicationRecord
  belongs_to :user

  validates :domain, presence: true, uniqueness: { scope: :user_id }
  validates :verification_status, inclusion: { in: %w[pending verified failed] }

  serialize :dns_records, coder: JSON

  scope :verified, -> { where(verification_status: "verified") }
  scope :pending, -> { where(verification_status: "pending") }

  def verified?
    verification_status == "verified"
  end

  def pending?
    verification_status == "pending"
  end

  def failed?
    verification_status == "failed"
  end

  def create_sendgrid_domain
    return if sendgrid_domain_id.present?

    response = SendgridService.new.create_domain(domain)

    if response[:success]
      update!(
        sendgrid_domain_id: response[:domain_id],
        dns_records: response[:dns_records],
        verification_status: "pending"
      )
      true
    else
      Rails.logger.error "Failed to create SendGrid domain for #{domain}: #{response[:error]}"
      update!(verification_status: "failed")

      # Store the error for debugging
      @last_error = response[:error]
      false
    end
  end

  def verify_domain
    return false unless sendgrid_domain_id.present?

    response = SendgridService.new.verify_domain(sendgrid_domain_id)

    if response[:success] && response[:verified]
      update!(
        verification_status: "verified",
        verified_at: Time.current
      )
      true
    else
      update!(verification_status: "failed")
      false
    end
  end

  def check_verification_status
    return unless sendgrid_domain_id.present?

    response = SendgridService.new.get_domain_status(sendgrid_domain_id)

    if response[:success]
      status = response[:verified] ? "verified" : "pending"
      update_attributes = { verification_status: status }
      update_attributes[:verified_at] = Time.current if status == "verified"

      update!(update_attributes)
    end
  end

  def last_error
    @last_error
  end
end
