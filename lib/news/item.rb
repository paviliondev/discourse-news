# frozen_string_literal: true

class News::Item
  def self.generate_body(html, featured_image_url)
    doc = Nokogiri::HTML5.fragment(html)

    doc.search("img[@src='#{featured_image_url}']").each(&:remove)
    doc.css(".lightbox-wrapper").each(&:remove)
    doc.css("p").each { |p| p.remove if p.content.blank? }

    doc.to_html
  end
end