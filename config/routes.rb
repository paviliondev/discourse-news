Discourse::Application.routes.prepend do
  get '/news' => 'list#news'
  get '/news/rss' => 'list#news_rss'
  get '/admin/plugins/news' => 'news/admin#index'
  post '/admin/plugins/news/excerpts' => 'news/admin#update_excerpts', constraints: AdminConstraint.new
end