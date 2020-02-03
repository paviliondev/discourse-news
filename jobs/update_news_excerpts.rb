# frozen_string_literal: true

module Jobs
  class UpdateNewsExcerpts < ::Jobs::Base
    def execute(args)
      return false if !SiteSetting.discourse_news_enabled
  
      category_ids = SiteSetting.discourse_news_category.split('|').map(&:to_i)
      
      Topic.where(category_id: category_ids).each do |topic|
        topic.custom_fields['news_excerpt'] = News::Topic.generate_excerpt(topic)
        topic.save_custom_fields(true)
      end
    end
  end
end