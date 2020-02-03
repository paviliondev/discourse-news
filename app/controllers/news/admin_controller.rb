class News::AdminController < Admin::AdminController
  def index
  end
  
  def update_excerpts
    if SiteSetting.discourse_news_enabled && SiteSetting.discourse_news_category.present?
      Jobs.enqueue(:update_news_excerpts)
      render json: success_json
    else
      render json: failed_json
    end
  end
end