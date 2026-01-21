# frozen_string_literal: true

RSpec.describe News::Item do
  describe ".generate_body" do
    it "removes the featured image from the body" do
      html = '<p>Hello</p><img src="https://example.com/featured.jpg"><p>World</p>'
      result = described_class.generate_body(html, "https://example.com/featured.jpg")

      expect(result).not_to include("featured.jpg")
      expect(result).to include("Hello")
      expect(result).to include("World")
    end

    it "removes lightbox wrappers" do
      html = '<p>Text</p><div class="lightbox-wrapper"><img src="test.jpg"></div><p>More</p>'
      result = described_class.generate_body(html, nil)

      expect(result).not_to include("lightbox-wrapper")
      expect(result).to include("Text")
      expect(result).to include("More")
    end

    it "removes empty paragraphs" do
      html = "<p>Content</p><p></p><p>   </p><p>More content</p>"
      result = described_class.generate_body(html, nil)

      doc = Nokogiri::HTML5.fragment(result)
      paragraphs = doc.css("p")

      expect(paragraphs.size).to eq(2)
      expect(paragraphs.map(&:text)).to contain_exactly("Content", "More content")
    end

    it "preserves valid HTML structure" do
      html = '<div class="content"><p>Paragraph</p><ul><li>Item 1</li><li>Item 2</li></ul></div>'
      result = described_class.generate_body(html, nil)

      expect(result).to include('<div class="content">')
      expect(result).to include("<ul>")
      expect(result).to include("<li>Item 1</li>")
    end
  end
end
