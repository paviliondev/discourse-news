class News::Item
  def self.generate_body(html, featured_image_url)
    doc = Nokogiri::HTML::fragment(html)
    
    ## Featured image is shown seperately
    doc.search("img[@src='#{featured_image_url}']").each { |n| n.remove } 
    
    doc.css(".lightbox-wrapper").find_all.each { |n| n.remove }
    
    ## Remove empty p elements
    doc.css('p').find_all.each { |p| p.remove if p.content.blank? }
    
    doc.to_html
  end
end