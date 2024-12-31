require "net/http"
require "uri"
require "json"

module Payment
  extend ActiveSupport::Concern

  API_URL = "https://test-api.creem.io/v1/checkouts"
  API_KEY = "creem_test_1hoBTkXDjgQJi6AHcOABF4"
  PRODUCTS = {
      "resonance" => "prod_3JnckOZ4aY8Ytw8riAGEWF",
      "echo"      => "prod_5pV4mr0T1rESraqRjNw92K",
      "whisper"   => "prod_1RS2SrBVdAxw6PjcuHjFJb"
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
      customer: {
        email: email
      }
    }.to_json
    response = http.request(request)
    response = JSON.parse(response.body)
    response["checkout_url"]
  end
end
