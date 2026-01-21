# frozen_string_literal: true

module News
  class Engine < ::Rails::Engine
    engine_name "news"
    isolate_namespace News
    config.autoload_paths << File.join(config.root, "lib")
  end
end