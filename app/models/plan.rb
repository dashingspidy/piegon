class Plan
  attr_reader :name

  LIMITS = {
    "free" => {
      contacts: 1,
      email_templates: 1,
      campaigns: 2,
      domain_verifications: 1,
      email_limit: 1000
    },
    "echo" => {
      contacts: 5,
      email_templates: 5,
      campaigns: Float::INFINITY,
      domain_verifications: 5,
      email_limit: 5000
    },
    "thunder" => {
      contacts: Float::INFINITY,
      email_templates: Float::INFINITY,
      campaigns: Float::INFINITY,
      domain_verifications: Float::INFINITY,
      email_limit: 10000
    }
  }.freeze

  def initialize(name)
    @name = name.to_s
  end

  def limit_for(resource)
    LIMITS.dig(name, resource.to_sym) || 0
  end

  def email_limit
    limit_for(:email_limit)
  end

  def unlimited_emails?
    email_limit == Float::INFINITY
  end

  def plan_details
    LIMITS[name] || {}
  end

  def valid_plan?
    LIMITS.key?(name)
  end

  def self.available_plans
    LIMITS.keys
  end

  def self.plan_comparison
    LIMITS.transform_values do |limits|
      limits.transform_values { |limit| limit == Float::INFINITY ? "Unlimited" : limit }
    end
  end
end
