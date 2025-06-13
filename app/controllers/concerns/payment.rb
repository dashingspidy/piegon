require "net/http"
require "uri"
require "json"

module Payment
  extend ActiveSupport::Concern

  API_URL = "https://api.creem.io/v1/checkouts"
  API_KEY = "creem_4x2oER23SBPEcDcZL4r4IX"
  PRODUCTS = {
      "echo"  => { id: "prod_2DZbUpGOu8G5K3ukSP26yW", price: 29 },
      "thunder" => { id: "prod_1EIBj1OR6bj0dRkkzzFzhz", price: 99 },
      "free"      => { id: "", price: 0 },
      "10000" => { id: "prod_3xzvgRwaRTL6V62Krf08bZ", price: 10, credits: 10000 }
  }.freeze

  def self.create_checkout(product_name, email)
    uri = URI.parse(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["x-api-key"] = API_KEY
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    request.body = {
      product_id: PRODUCTS[product_name][:id],
      success_url: "https://piegon.pro/billing_accounts",
      customer: {
        email: email
      }
    }.to_json
    response = http.request(request)
    response = JSON.parse(response.body)
    response["checkout_url"]
  end

  def self.create_seat_based_checkout(product_name, email, units)
    uri = URI.parse(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["x-api-key"] = API_KEY
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    request.body = {
      product_id: PRODUCTS[product_name][:id],
      units: units,
      success_url: "https://piegon.pro/billing_accounts",
      customer: {
        email: email
      }
    }.to_json
    response = http.request(request)
    response = JSON.parse(response.body)
    response["checkout_url"]
  end

  def self.customer_portal(customer_id)
    uri = URI.parse("https://api.creem.io/v1/customers/billing")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["x-api-key"] = API_KEY
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    request.body = {
      "customer_id": "#{customer_id}"
    }.to_json

    response = http.request(request)
    response = JSON.parse(response.body)
    response["customer_portal_link"]
  end

  def self.email_credit_packages
    PRODUCTS.select { |key, _| key.start_with?("email_") }
  end

  def current_plan
    Plan.new(Current.user.plan)
  end

  def free_account?
    current_plan.name == "free"
  end

  def can_send_email?
    !Current.user.plan.blank? && Current.user.mail_settings.present?
  end
end
