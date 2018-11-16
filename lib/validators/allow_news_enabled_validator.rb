class AllowNewsEnabledValidator
  def initialize(opts = {})
    @opts = opts
  end

  def valid_value?(val)
    return true if val == "f"
    defined?(TopicPreviews) == 'constant' && TopicPreviews.class == Module
  end

  def error_message
    I18n.t("site_settings.errors.topic_list_previews_not_installed");
  end
end
