# AGENTS.md — discourse-news

A Discourse plugin that adds a `/news` route displaying topics in a news-article layout, with optional RSS feed source and a sidebar topic list.

## Plugin structure

Standard Discourse plugin layout. Entry point is `plugin.rb`.

```
plugin.rb                        # Asset registration, gating on enabled setting, monkey-patches
app/serializers/news/            # ActiveModel serializers (RSS items)
assets/javascripts/discourse/    # Frontend: components, connectors, controllers, routes, templates
assets/stylesheets/              # common/ and mobile/ SCSS
config/routes.rb                 # GET /news => list#news
config/settings.yml              # 11 site settings (see below)
lib/news/                        # Ruby backend: RSS fetching, item HTML processing, engine
spec/                            # RSpec unit + system (browser) tests
```

## Running tests

This plugin runs inside a full Discourse checkout — it cannot be tested standalone. Tests run through Discourse's CI infrastructure.

CI is handled entirely by the shared reusable workflow in `.github/workflows/discourse-plugin.yml`, which delegates to `discourse/.github/.github/workflows/discourse-plugin.yml@v1`. That shared workflow runs:
- Ruby linting (RuboCop)
- JavaScript linting (ESLint)
- RSpec unit tests
- System (browser/Capybara) tests

There is no local `Makefile`, `Rakefile`, or task runner script.

## Linting

Ruby: `rubocop` via `rubocop-discourse` (inherits `stree-compat.yml`).

```sh
bundle exec rubocop
```

## Frontend conventions

- All components and templates use **Glimmer `.gjs`** (template-colocation) with `@glimmer/component`. There are no legacy `.hbs` files.
- Route template: `templates/news.gjs` — uses `<DiscoveryTopicsList>` + `<List>` (from `discourse/components/topic-list/list`, not the deprecated `discourse/components/topic-list` shim).
- The outlet connector at `assets/javascripts/discourse/connectors/topic-list-item/news-topic-list-item.gjs` replaces the default topic list item when on the news route; uses `@outletArgs.topic` (not `@topic`).
- Header icon is registered in the api-initializer via `api.headerIcons.add()` (not `api.headerButtons.add()`).
- In api-initializers, `api.siteSettings` does **not** exist — use `api.container.lookup("service:site-settings")` to access site settings. In Glimmer components and services, use `@service siteSettings` instead.
- Do **not** use Ember string prototype extensions (removed in recent commits).
- Route model returns sidebar topics via `Object.assign(base, { sidebarTopics })` — do not use `controller.set()`.
- `bulkSelectHelper` belongs to `DiscoveryListController`, referenced as `@controller.bulkSelectHelper` in templates.
- Triple-mustache `{{{...}}}` is gone — use `{{htmlSafe (i18n ...)}}` for HTML-safe i18n strings.
- `(action "changeSort")` is gone — use `@changeSort={{@controller.changeSort}}` (the action is already bound via `@action`).

## Backend conventions

- `News::Rss` fetches via `Excon`, parses with `RSS::Parser`, caches in `Discourse.cache` with a 5-minute TTL.
- `News::Item` uses `Nokogiri::HTML5` to strip featured images, lightbox wrappers, and empty `<p>` tags from post bodies.
- `ListController` is monkey-patched to skip `ensure_logged_in` for `/news` (unauthenticated access is intentional).
- `plugin.rb` adds `list_controller#news`, `topic_query#list_news`, and `topic#news_body` as computed attributes; `news_body` is serialized on `topic_list_item` conditionally.

## Site settings (config/settings.yml)

| Setting | Type | Default | Notes |
|---|---|---|---|
| `discourse_news_enabled` | bool | `false` | Master switch; plugin is gated on this |
| `discourse_news_source` | enum | `"category"` | `category` or `rss` |
| `discourse_news_category` | category_list | `''` | Categories for news topics |
| `discourse_news_rss` | string | `''` | RSS feed URL (server-side only) |
| `discourse_news_icon` | string | `''` | FA icon or image URL for header nav button |
| `discourse_news_title_below_image` | bool | `false` | Layout option |
| `discourse_news_show_reply_count` | bool | `false` | Category source only |
| `discourse_news_sort` | enum | `"bumped_at"` | `bumped_at` or `created_at` (server-side only) |
| `discourse_news_sidebar_topic_list` | bool | `true` | Show sidebar |
| `discourse_news_sidebar_topic_list_filter` | string | `"latest"` | Sidebar filter |
| `discourse_news_sidebar_topic_list_limit` | int | `10` | Sidebar count |

## Discourse compatibility

`.discourse-compatibility` pins commit `289c736c` for Discourse `3.1.0.beta4`. The plugin targets modern Discourse (Glimmer components, updated share modal API, CSS custom properties for dark mode). It has been migrated to be compatible with Discourse 2026.04, removing deprecated APIs (`MultiJson`, `ActiveModel::ArraySerializer`, `api.headerButtons`, curly-syntax templates, `controller.set()`).

## Repo context

Fork of `paviliondev/discourse-news`, maintained at `darktable-fr/discourse-news`. Branch `main` is the active branch.

## Work performed

### Responsive layout fixes (2026-04-24)

Fixed horizontal scroll and layout issues across viewports in `/news` route.

- Desktop (≥1025px): flex layout, article column 750px max, sidebar visible
- Tablet (≤1024px): sidebar hidden, column 100%, title 28px
- Mobile: full column, title 22px, thumbnails full width ratio-preserved

**CSS changes:**
- Removed fixed `width: 750px`, use `max-width: 100%` + `min-width: 0` + `overflow-x: hidden`
- Added `@media (max-width: 1024px)` hiding sidebar and forcing column layout
- Rewrote mobile SCSS: removed `!important`, set `height: auto` for thumbnails
- Added `.news-item-body img { max-width: 100%; height: auto }` to constrain inline images
- Removed `object-fit: cover` from thumbnail img rules (no-op without explicit height)
