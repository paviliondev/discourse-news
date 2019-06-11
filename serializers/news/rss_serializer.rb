class News::RssSerializer < ApplicationSerializer
  attributes :title,
             :description,
             :url,
             :image_url

  def description
    PrettyText.excerpt(object.description, SiteSetting.discourse_news_excerpt_length, keep_emoji_images: true)
  end
end
