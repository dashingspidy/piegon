require "net/http"
require "uri"
require "json"

module Payment
  extend ActiveSupport::Concern

  API_URL = "https://api.creem.io/v1/checkouts"
  API_KEY = "creem_4x2oER23SBPEcDcZL4r4IX"
  PRODUCTS = {
      "lifetime"  => "prod_2DZbUpGOu8G5K3ukSP26yW",
      "thunder"   => "prod_6CyPOsSvhDJY8S6fNm2aWQ",
      "resonance" => "prod_4As6TLeqHEKv4Ke2ZIugJI",
      "echo"      => "prod_5JnWM2R0tec5w9GBuEGQK4",
      "whisper"   => "prod_3MYGwNyNuWU3QofK7OMm15"
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
      product_id: PRODUCTS[product_name],
      success_url: "https://piegon.pro/dashboard",
      customer: {
        email: email
      }
    }.to_json
    response = http.request(request)
    response = JSON.parse(response.body)
    response["checkout_url"]
  end
end
