# frozen_string_literal: true

Discourse::Application.routes.prepend { get "news" => "list#news" }
