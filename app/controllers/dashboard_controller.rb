class DashboardController < ApplicationController
  PRODUCTS = {
    "prod_3JnckOZ4aY8Ytw8riAGEWF" => "50000",
    "prod_5pV4mr0T1rESraqRjNw92K" => "30000",
    "prod_1RS2SrBVdAxw6PjcuHjFJb" => "10000"
  }.freeze
  def index
    if params[:order_id] && params[:product_id]
      product = params[:product_id]
      Current.user.update(email_limit: PRODUCTS[product])
    end
  end
end
