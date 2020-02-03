require 'digest/sha1'
require 'excon'
require 'rss'
require_dependency 'encodings'

PARSING_ERRORS = [::RSS::NotWellFormedError, ::RSS::InvalidRSSError]

class News::Rss
  include ActiveModel::SerializerSupport
 
  attr_accessor :title,
                :description,
                :url,
                :image_url
              
  attr_accessor :category,
                :pinned_until,
                :last_posted_at,
                :created_at,
                :posts_count

  def initialize(attrs)
    @attrs = attrs
    @title = attrs.title
    @url = attrs.link
        
    @category = nil
    @pinned_until = nil
    @last_posted_at = nil
    @created_at = attrs.pubDate || Date.now
    @posts_count = nil
  end
  
  def description
    @description ||= News::Item.generate_body(@attrs.description, @image_url)
  end
  
  def image_url
    @image_url ||= begin
      if @attrs.enclosure &&
         @attrs.enclosure.type.include?("image") &&
         @attrs.enclosure.url
        @attrs.enclosure.url
      else
        nil
      end
    end
  end

  def self.get_feed_items(url)
    rss = self.get_parsed_feed(url)
    items = rss.items.map { |item| self.new(item) }

    self.cache_feed(url, items)

    items
  end

  def self.get_parsed_feed(url)
    raw_feed, encoding = self.fetch_rss(url)
    return nil if raw_feed.nil?

    encoded_feed = Encodings.try_utf8(raw_feed, encoding) if encoding
    encoded_feed = Encodings.to_utf8(raw_feed) unless encoded_feed

    return nil if encoded_feed.blank?

    ## ensure enclosure images have length
    encoded_feed = encoded_feed.gsub(/\"\"/, '"0"')

    ::RSS::Parser.parse(encoded_feed)
  rescue *PARSING_ERRORS => e
    puts "NEWS RSS PARSING ERROR: #{e}"
  end

  def self.fetch_rss(url)
    response = Excon.new(url.to_s).request(method: :get, expects: 200)
    [response.body, self.detect_charset(response)]
  end

  def self.detect_charset(response)
    if response.headers['Content-Type'] =~ /charset\s*=\s*([a-z0-9\-]+)/i
      Encoding.find($1)
    end
  rescue ArgumentError
    nil
  end

  def self.cached_feed(url)
    Discourse.cache.fetch(self.cache_key(url))
  end

  def self.cache_feed(url, feed)
    Discourse.cache.write(self.cache_key(url), feed, expires_in: 5.minutes)
  end
  
  def self.clear_cache(url)
    Discourse.cache.delete(self.cache_key(url))
  end

  def self.cache_key(url)
    "news_rss:#{url}"
  end
end
