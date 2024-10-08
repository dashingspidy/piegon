class CampaignsController < ApplicationController
  def index
    @campaigns = Current.user.campaigns
  end

  def new
    @campaign = Current.user.campaigns.new
  end

  def create
    @campaign = Current.user.campaigns.build(campaign_params)
    if @campaign.save
      redirect_to campaigns_path, notice: "New campaign created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name)
  end
end
