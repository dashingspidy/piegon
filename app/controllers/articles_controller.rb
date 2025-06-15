class ArticlesController < ApplicationController
  include Pagy::Backend
  allow_unauthenticated_access

  def index
    @latest_article = Article.recent.first
    @pagy, @articles = pagy(Article.recent.offset(1), limit: 12)
  end

  def show
    @article = Article.find_by!(slug: params[:id])
  end
end
