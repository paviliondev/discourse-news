class News::Topic
  def self.generate_excerpt(topic)
    doc = Nokogiri::HTML::fragment(topic.first_post.cooked)
    doc.search('.//img').remove
    PrettyText.excerpt(
      doc.to_html,
      SiteSetting.discourse_news_excerpt_length,
      keep_emoji_images: true
    )
  end
end