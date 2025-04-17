require "net/http"
require "uri"
require "json"

module Payment
  extend ActiveSupport::Concern

  API_URL = "https://api.creem.io/v1/checkouts"
  API_KEY = "creem_4x2oER23SBPEcDcZL4r4IX"
  PRODUCTS = {
      "echo"  => { id: "prod_2DZbUpGOu8G5K3ukSP26yW", price: 99 },
      "whisper" => { id: "prod_3BdRN1jqov4CYCMcrviiSe", price: 179 },
      "thunder" => { id: "prod_1EIBj1OR6bj0dRkkzzFzhz", price: 399 },
      "free"      => { id: "", price: 0 }
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

  private

  def free_account?
    Current.user.plan == "free"
  end

  def can_send_email?
    false if Current.user.plan.blank? || Current.user.mail_settings.blank?
  end
end
