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

  def initialize(attrs)
    @title = attrs.title
    @description = attrs.description
    @url = attrs.link

    if attrs.enclosure &&
       attrs.enclosure.type.include?("image") &&
       attrs.enclosure.url
      @image_url = attrs.enclosure.url
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
    Discourse.cache.write(self.cache_key(url), feed, force: true, expires_in: 1.hour)
  end

  def self.cache_key(url)
    "news_rss:#{url}"
  end
end
