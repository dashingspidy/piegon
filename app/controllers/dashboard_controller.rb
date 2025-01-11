class DashboardController < ApplicationController
  PRODUCTS = {
    "prod_6CyPOsSvhDJY8S6fNm2aWQ" => "50000",
    "prod_4As6TLeqHEKv4Ke2ZIugJI" => "30000",
    "prod_5JnWM2R0tec5w9GBuEGQK4" => "10000",
    "prod_3MYGwNyNuWU3QofK7OMm15" => "50000",
    "prod_2DZbUpGOu8G5K3ukSP26yW" => "0"
  }.freeze
  def index
    if params[:order_id] && params[:product_id]
      product = params[:product_id]
      Current.user.update(email_limit: PRODUCTS[product])
    end

    @campaign_count = Current.user.campaigns.size
    @total_subscribers = Current.user.campaigns.sum { |c| c.subscribers.size }
  end
end
