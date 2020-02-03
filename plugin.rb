# name: Discourse News
# about: Adds a "News" stream to your Discourse instance
# version: 0.3
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-news

register_asset 'stylesheets/common/discourse-news.scss'
register_asset 'stylesheets/mobile/discourse-news.scss', :mobile

add_admin_route 'news.title', 'news'

enabled_site_setting :discourse_news_enabled

after_initialize do
  %w[
    ../lib/news/engine.rb
    ../lib/news/rss.rb
    ../lib/news/topic.rb
    ../config/routes.rb
    ../app/controllers/news/admin_controller.rb
    ../app/serializers/news/rss_serializer.rb
    ../jobs/update_news_excerpts.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end
  
  add_to_class(:list_controller, :news) do
    respond_with_list(TopicQuery.new(current_user).list_news)
  end
  
  add_to_class(:list_controller, :news_rss) do
    feed_url = SiteSetting.discourse_news_rss
    feed = News::Rss.cached_feed(feed_url)

    unless feed.present?
      feed = News::Rss.get_feed_items(feed_url)
    end

    render json: ActiveModel::ArraySerializer.new(feed, each_serializer: News::RssSerializer, root: false)
  end
  
  add_to_class(:topic_query, :list_news) do
    category_ids = [*SiteSetting.discourse_news_category.split("|")]
    topics = Topic.joins(:category).where('categories.id IN (?)', category_ids)
    topics = topics.joins("LEFT OUTER JOIN topic_users AS tu ON (topics.id = tu.topic_id AND tu.user_id = #{@user.id.to_i})")
      .references('tu') if @user
    topics = topics.order("topics.#{SiteSetting.discourse_news_sort} DESC")

    create_list(:news, { no_definitions: true }, topics)
  end
  
  add_to_class(:topic, :news_item) do
    category_ids = SiteSetting.discourse_news_category.split('|').map(&:to_i)
    category_ids.include? category_id.to_i
  end
  
  add_to_class(:topic, :news_excerpt) do
    if news_item
      custom_fields['news_excerpt'] || ''
    else
      nil
    end
  end
  
  add_model_callback(:post, :after_commit) do
    if is_first_post? && topic.news_item
      topic.custom_fields['news_excerpt'] = News::Topic.generate_excerpt(topic)
      topic.save_custom_fields(true)
    end
  end
  
  add_to_serializer(:topic_list_item, :include_news_excerpt?) do
    object.news_item
  end
  
  add_to_serializer(:topic_list_item, :news_excerpt) do
    object.news_excerpt
  end
  
  TopicList.preloaded_custom_fields << 'news_excerpt' if TopicList.respond_to? :preloaded_custom_fields
end
