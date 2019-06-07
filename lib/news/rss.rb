class News::Rss
  attr_accessor :title,
                :description,
                :url

  def initialize(attrs)
    @title = attrs.title
    @description = attrs.description
    @url = attrs.link
  end

  def self.get_feed_items(url)
    rss = SimpleRSS.parse open(url)
    rss.items.map { |item| self.new(item) }
  end
end
