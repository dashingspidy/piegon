class Plan
  attr_reader :name

  LIMITS = {
    "free" => {
      contacts: 1,
      email_templates: 1,
      campaigns: 2,
      domain_verifications: 1
    },
    "echo" => {
      contacts: 5,
      email_templates: 5,
      campaigns: Float::INFINITY,
      domain_verifications: 5
    },
    "thunder" => {
      contacts: Float::INFINITY,
      email_templates: Float::INFINITY,
      campaigns: Float::INFINITY,
      domain_verifications: Float::INFINITY
    }
  }.freeze

  def initialize(name)
    @name = name.to_s
  end

  def limit_for(resource)
    LIMITS.dig(name, resource.to_sym) || 0
  end
end
