Discourse::Application.routes.prepend do
  get 'news' => 'list#news'
end