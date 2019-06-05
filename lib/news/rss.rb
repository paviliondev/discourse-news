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
    items = []
    open(url) do |rss|
      feed = ::RSS::Parser.parse(rss)
      feed.items.each do |item|
        items.push(self.new(item))
      end
    end
    items
  end
end
