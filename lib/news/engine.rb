module News
  class Engine < ::Rails::Engine
    engine_name 'news'
    isolate_namespace News
  end
end