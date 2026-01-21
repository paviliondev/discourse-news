# frozen_string_literal: true

RSpec.describe News::Rss do
  let(:sample_rss) do
    <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>Test Feed</title>
          <link>https://example.com</link>
          <description>A test feed</description>
          <item>
            <title>Test Article</title>
            <link>https://example.com/article</link>
            <description><![CDATA[<p>Article content</p>]]></description>
            <pubDate>Mon, 20 Jan 2025 10:00:00 +0000</pubDate>
          </item>
          <item>
            <title>Article with Image</title>
            <link>https://example.com/article2</link>
            <description><![CDATA[<p>More content</p>]]></description>
            <enclosure url="https://example.com/image.jpg" type="image/jpeg" length="12345"/>
            <pubDate>Tue, 21 Jan 2025 10:00:00 +0000</pubDate>
          </item>
        </channel>
      </rss>
    RSS
  end

  describe ".detect_charset" do
    it "extracts charset from Content-Type header" do
      response = double(headers: { "Content-Type" => "text/xml; charset=ISO-8859-1" })
      charset = described_class.detect_charset(response)

      expect(charset).to eq(Encoding::ISO_8859_1)
    end

    it "returns nil for missing charset" do
      response = double(headers: { "Content-Type" => "text/xml" })
      charset = described_class.detect_charset(response)

      expect(charset).to be_nil
    end

    it "returns nil for invalid charset" do
      response = double(headers: { "Content-Type" => "text/xml; charset=invalid-encoding" })
      charset = described_class.detect_charset(response)

      expect(charset).to be_nil
    end
  end

  describe ".cache_key" do
    it "generates consistent cache keys" do
      url = "https://example.com/feed.rss"
      expect(described_class.cache_key(url)).to eq("news_rss:#{url}")
    end
  end

  describe "instance methods" do
    let(:parsed_feed) { RSS::Parser.parse(sample_rss) }
    let(:item_without_image) { described_class.new(parsed_feed.items.first) }
    let(:item_with_image) { described_class.new(parsed_feed.items.last) }

    describe "#title" do
      it "returns the item title" do
        expect(item_without_image.title).to eq("Test Article")
      end
    end

    describe "#url" do
      it "returns the item link" do
        expect(item_without_image.url).to eq("https://example.com/article")
      end
    end

    describe "#image_url" do
      it "returns nil when no enclosure" do
        expect(item_without_image.image_url).to be_nil
      end

      it "returns enclosure URL for image type" do
        expect(item_with_image.image_url).to eq("https://example.com/image.jpg")
      end
    end

    describe "#description" do
      it "processes the description through News::Item.generate_body" do
        expect(item_without_image.description).to include("Article content")
      end
    end

    describe "#created_at" do
      it "parses the pubDate" do
        expect(item_without_image.created_at).to be_a(Time)
      end

      it "defaults to now when pubDate is missing" do
        rss_no_date = <<~RSS
          <?xml version="1.0" encoding="UTF-8"?>
          <rss version="2.0">
            <channel>
              <title>Test</title>
              <link>https://example.com</link>
              <description>Test feed</description>
              <item>
                <title>No Date</title>
                <link>https://example.com/item</link>
                <description>Test</description>
              </item>
            </channel>
          </rss>
        RSS
        feed = RSS::Parser.parse(rss_no_date)
        item = described_class.new(feed.items.first)

        expect(item.created_at).to be_within(1.minute).of(DateTime.now)
      end
    end
  end

  describe "caching" do
    it "caches and retrieves feed" do
      items = %w[item1 item2]
      url = "https://example.com/feed.rss"

      described_class.cache_feed(url, items)
      cached = described_class.cached_feed(url)

      expect(cached).to eq(items)
    end

    it "clears cache" do
      url = "https://example.com/feed.rss"
      described_class.cache_feed(url, ["item"])
      described_class.clear_cache(url)

      expect(described_class.cached_feed(url)).to be_nil
    end
  end
end
