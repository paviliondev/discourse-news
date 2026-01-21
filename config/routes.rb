# frozen_string_literal: true

Discourse::Application.routes.prepend do
  get 'news' => 'list#news'
end