# frozen_string_literal: true

# name: discourse-news
# about: Adds a news stream to your Discourse instance
# version: 0.3
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-news

register_asset 'stylesheets/common/discourse-news.scss'
register_asset 'stylesheets/mobile/discourse-news.scss', :mobile

enabled_site_setting :discourse_news_enabled

after_initialize do
  %w[
    ../lib/news/engine.rb
    ../lib/news/item.rb
    ../lib/news/rss.rb
    ../lib/news/rss_topic_list.rb
    ../config/routes.rb
    ../app/serializers/news/rss_serializer.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  add_to_class(:list_controller, :news) do
    if SiteSetting.discourse_news_source == 'rss'
      feed_url = SiteSetting.discourse_news_rss
      feed = News::Rss.get_feed_items(feed_url) ## TODO implement caching: News::Rss.cached_feed(feed_url)
      
      serialized = ActiveModel::ArraySerializer.new(feed, each_serializer: News::RssSerializer, root: false)
      
      respond_to do |format|
        format.html do
          @list = RssTopicList.new(feed, nil)
          store_preloaded("topic_list_news_rss", MultiJson.dump(serialized))
          render 'list/list'
        end
        format.json do
          render json: serialized
        end
      end
    else
      respond_with_list(TopicQuery.new(current_user).list_news)
    end
  end
  
  add_to_class(:topic_query, :list_news) do
    category_ids = [*SiteSetting.discourse_news_category.split("|")]
    
    topics = Topic.joins(:category).where('categories.id IN (?)', category_ids)
    topics = topics.joins("
      LEFT OUTER JOIN topic_users AS tu ON (
        topics.id = tu.topic_id AND tu.user_id = #{@user.id.to_i}
      )"
    ).references('tu') if @user
    
    topics = topics.where('COALESCE(categories.topic_id, 0) <> topics.id')
    
    topics = topics.order("topics.#{SiteSetting.discourse_news_sort} DESC")

    create_list(:news, {}, topics)
  end
  
  add_to_class(:topic, :news_item) do
    category_ids = SiteSetting.discourse_news_category.split('|').map(&:to_i)
    category_ids.include? category_id.to_i
  end
  
  add_to_class(:topic, :news_body) do
    @news_body ||= begin
      if news_item
        News::Item.generate_body(first_post.cooked, image_url)
      else
        nil
      end
    end
  end
  
  module TopicNewsExtension
    def reload(options = nil)
      @news_body = nil
      super(options)
    end
  end
  
  class ::Topic
    prepend TopicNewsExtension
  end
  
  add_to_serializer(:topic_list_item, :include_news_body?) do
    object.news_item
  end
  
  add_to_serializer(:topic_list_item, :news_body) do
    object.news_body
  end
end
