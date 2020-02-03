class News::RssSerializer < ::ApplicationSerializer
  attributes :title,
             :description,
             :url,
             :image_url
end
