# name: Discourse News
# about: Adds a "News" stream to your Discourse instance
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-news

register_asset 'stylesheets/common/discourse-news.scss'
register_asset 'stylesheets/mobile/discourse-news.scss', :mobile

enabled_site_setting :discourse_news_enabled

load File.expand_path('../lib/validators/allow_news_enabled_validator.rb', __FILE__)

NEWS_THUMB_HEIGHT = 400
NEWS_THUMB_WIDTH = 700

after_initialize do
  Discourse::Application.routes.prepend do
    get '/news' => 'list#news'
    get '/news/rss' => 'list#news_rss'
  end

  require_dependency 'application_controller'
  module ::News
    class Engine < ::Rails::Engine
      engine_name 'news'
      isolate_namespace News
    end
  end

  load File.expand_path('../lib/news/rss.rb', __FILE__)

  require_dependency 'list_controller'
  class ::ListController
    skip_before_action :ensure_logged_in, only: [:news, :news_rss]

    def news
      list_opts = {
        category: SiteSetting.discourse_news_category,
        no_definitions: true
      }

      list = TopicQuery.new(nil, list_opts).public_send("list_latest")

      respond_with_list(list)
    end

    def news_rss
      feed_url = SiteSetting.discourse_news_rss
      feed = News::Rss.cached_feed(feed_url)

      unless feed.present?
        feed = News::Rss.get_feed_items(feed_url)
      end

      render json: success_json.merge(list: feed)
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

    def thumbnails
      if object.news_item
        original_images
      else
        super
      end
    end
  end

  require_dependency 'topic_list_item_serializer'
  class ::TopicListItemSerializer
    prepend NewsItemExtension
  end
end
