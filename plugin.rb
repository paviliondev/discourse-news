# name: Discourse News
# about: Adds a "News" stream to your Discourse instance
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-news

register_asset 'stylesheets/common/discourse-news.scss'
register_asset 'stylesheets/mobile/discourse-news.scss', :mobile

enabled_site_setting :discourse_news_enabled

load File.expand_path('../lib/validators/allow_news_enabled_validator.rb', __FILE__)

NEWS_THUMB_HEIGHT = 700
NEWS_THUMB_WIDTH = 400

after_initialize do
  Discourse::Application.routes.prepend do
    get '/news' => 'list#news'
  end

  require_dependency 'list_controller'
  class ::ListController
    def news
      list_opts = {
        category: SiteSetting.discourse_news_category,
        no_definitions: true
      }

      list = TopicQuery.new(current_user, list_opts).public_send("list_latest")

      respond_with_list(list)
    end
  end

  require_dependency 'topic'
  class ::Topic
    def news_item
      category_id.to_i == SiteSetting.discourse_news_category.to_i
    end
  end

  require_dependency 'category'
  class ::Category
    def custom_thumbnail_height
      if id.to_i == SiteSetting.discourse_news_category.to_i
        NEWS_THUMB_HEIGHT
      end
    end

    def custom_thumbnail_width
      if id.to_i == SiteSetting.discourse_news_category.to_i
        NEWS_THUMB_WIDTH
      end
    end
  end

  module NewsItemExtension
    def excerpt
      if object.news_item
        doc = Nokogiri::HTML::fragment(object.previewed_post.cooked)
        doc.search('.//img').remove
        return PrettyText.excerpt(doc.to_html, 10000, keep_emoji_images: true)
      end
      super
    end
  end

  require_dependency 'topic_list_item_serializer'
  class ::TopicListItemSerializer
    prepend NewsItemExtension
  end
end
