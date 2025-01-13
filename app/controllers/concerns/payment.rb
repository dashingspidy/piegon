require "net/http"
require "uri"
require "json"

module Payment
  extend ActiveSupport::Concern

  API_URL = "https://api.creem.io/v1/checkouts"
  API_KEY = "creem_4x2oER23SBPEcDcZL4r4IX"
  PRODUCTS = {
      "lifetime"  => { id: "prod_2DZbUpGOu8G5K3ukSP26yW", email_limit: "0", price: 99 },
      "thunder"   => { id: "prod_6CyPOsSvhDJY8S6fNm2aWQ", email_limit: "50000", price: 99 },
      "resonance" => { id: "prod_4As6TLeqHEKv4Ke2ZIugJI", email_limit: "30000", price: 60 },
      "echo"      => { id: "prod_5JnWM2R0tec5w9GBuEGQK4", email_limit: "10000", price: 20 },
      "whisper"   => { id: "prod_3MYGwNyNuWU3QofK7OMm15", email_limit: "5000", price: 12 },
      "free"      => { id: "", email_limit: "0", price: 0 }
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
      success_url: "https://piegon.pro/dashboard",
      customer: {
        email: email
      }
    }.to_json
    response = http.request(request)
    response = JSON.parse(response.body)
    response["checkout_url"]
  end

  def self.create_update_checkout(plan)
    uri = URI.parse(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["x-api-key"] = API_KEY
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    request.body = {
      product_id: PRODUCTS[plan][:id],
      success_url: "https://piegon.pro/dashboard",
      customer: {
        email: Current.user.email_address
      }
    }.to_json

    response = http.request(request)
    parsed_response = JSON.parse(response.body)
    parsed_response["checkout_url"]
  end

  def cancel_subscription(subs_id)
    uri = URI.parse("https://api.creem.io/v1/subscriptions/#{subs_id}/cancel")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["x-api-key"] = API_KEY
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"

    http.request(request)
  end

  private

  def free_account?
    false if Current.user.plan == "free"
  end

  def can_send_email?
    return false if Current.user.plan.blank?
    emails_sent_this_month < Current.user.email_limit
  end

  def emails_sent_this_month
    EmailLog.where(user_id: Current.user.id).where("created_at >= ?", Time.current.beginning_of_month).count
  end

  def remaining_emails
    return 0 if Current.user.plan == "free" || Current.user.plan == "lifetime"
    return 0 if Current.user.email_limit.nil?
    [ 0, Current.user.email_limit - emails_sent_this_month ].max
  end

  def check_email_limit
    return if can_send_email?

    if Current.user.plan == "lifetime"
      flash[:alert] = "Please bring either your API/SMTP settings or purchase our email credit."
    else
      flash[:alert] = "Monthly email limit reached. Please buy additional email credit."
    end
    redirect_to dashboard_path
  end
end
