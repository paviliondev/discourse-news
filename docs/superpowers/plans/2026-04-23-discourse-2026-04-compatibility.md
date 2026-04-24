# Discourse 2026.04 Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rendre le plugin discourse-news compatible avec Discourse 2026.04 en corrigeant 6 fichiers qui contiennent des APIs supprimées ou des patterns Ember/Rails obsolètes.

**Architecture:** Les problèmes sont répartis en deux domaines indépendants — Ruby (plugin.rb) et JavaScript (templates + initializers + connector). Les tâches Ruby ne dépendent pas des tâches JS et peuvent être faites dans n'importe quel ordre. La tâche de conversion `news.hbs → news.gjs` dépend de la tâche route car le template lit `@model.sidebarTopics`.

**Tech Stack:** Glimmer components (.gjs), `apiInitializer`, `discourse/components/topic-list/list`, ActiveModelSerializers 0.10, Discourse plugin API

---

## Fichiers modifiés

| Tâche | Fichier | Action |
|---|---|---|
| 1 | `plugin.rb` | 3 corrections Ruby : MultiJson, ArraySerializer, include_condition |
| 2 | `assets/javascripts/discourse/api-initializers/discourse-news.gjs` | Remplacer `api.container.lookup` par `api.siteSettings` |
| 3 | `assets/javascripts/discourse/controllers/news.js` | Ajouter `@service site` et `@service siteSettings` |
| 4 | `assets/javascripts/discourse/routes/news.js` | Passer sidebarTopics via le modèle, supprimer controller.set |
| 5 | `assets/javascripts/discourse/templates/news.hbs` → `news.gjs` | Conversion complète HBS → GJS |
| 6 | `assets/javascripts/discourse/connectors/topic-list-item/news-topic-list-item.gjs` | `@topic` → `@outletArgs.topic`, supprimer `{{yield}}` |

---

## Task 1 : Corriger plugin.rb — 3 bugs Ruby critiques

**Files:**
- Modify: `plugin.rb:28,33,88`

### Contexte

Trois patterns supprimés/brisés dans Discourse 2026.04 :
1. `MultiJson` (gem supprimée) — L.33
2. `ActiveModel::ArraySerializer` (AMS 0.8 legacy) — L.28
3. `include_condition:` keyword de `add_to_serializer` — L.88

### Steps

- [ ] **Step 1 : Corriger MultiJson et ArraySerializer (L.28 et L.33)**

Dans `plugin.rb`, remplacer le bloc `add_to_class(:list_controller, :news)` en entier :

```ruby
# Avant (L.28-38) :
serialized = ActiveModel::ArraySerializer.new(feed, each_serializer: News::RssSerializer, root: false)

respond_to do |format|
  format.html do
    @list = News::RssTopicList.new(feed, nil)
    store_preloaded("topic_list_news_rss", MultiJson.dump(serialized))
    render 'list/list'
  end
  format.json do
    render json: serialized
  end
end

# Après :
serialized = ActiveModelSerializers::SerializableResource.new(
  feed,
  each_serializer: News::RssSerializer,
  root: false
)

respond_to do |format|
  format.html do
    @list = News::RssTopicList.new(feed, nil)
    store_preloaded("topic_list_news_rss", serialized.to_json)
    render 'list/list'
  end
  format.json do
    render json: serialized
  end
end
```

- [ ] **Step 2 : Corriger include_condition (L.88-90)**

Remplacer :

```ruby
# Avant :
add_to_serializer(:topic_list_item, :news_body, include_condition: -> { object.news_item }) do
  object.news_body
end

# Après :
add_to_serializer(:topic_list_item, :news_body) do
  object.news_body
end

add_to_serializer(:topic_list_item, :include_news_body?) do
  object.news_item
end
```

- [ ] **Step 3 : Vérifier la syntaxe Ruby**

```bash
cd /mnt/media1.intra/Dev/Dev/Andy/github/discourse-news
ruby -c plugin.rb
```

Résultat attendu : `Syntax OK`

- [ ] **Step 4 : Commit**

```bash
git add plugin.rb
git commit -m "fix: remove MultiJson, ArraySerializer legacy, and include_condition keyword from plugin.rb"
```

---

## Task 2 : Corriger api-initializers/discourse-news.gjs — api.container.lookup déprécié

**Files:**
- Modify: `assets/javascripts/discourse/api-initializers/discourse-news.gjs`

### Contexte

`api.container.lookup("service:site-settings")` est une API de bas niveau dépréciée. L'objet `api` expose directement `api.siteSettings`.

### Steps

- [ ] **Step 1 : Remplacer le lookup container**

Contenu complet du fichier après modification :

```javascript
import { apiInitializer } from "discourse/lib/api";
import NewsHeaderButton from "../components/news-header-button";

export default apiInitializer("1.0", (api) => {
  if (!api.siteSettings.discourse_news_enabled) {
    return;
  }

  api.headerButtons.add("news", NewsHeaderButton, { before: "auth" });

  api.modifyClass(
    "model:topic",
    (Superclass) =>
      class extends Superclass {
        get basicCategoryLinkHtml() {
          const category = this.category;
          if (!category) {
            return "";
          }
          return `<a class="basic-category-link" href="${category.url}" title="${category.name}">${category.name}</a>`;
        }
      }
  );
});
```

- [ ] **Step 2 : Commit**

```bash
git add assets/javascripts/discourse/api-initializers/discourse-news.gjs
git commit -m "fix: replace api.container.lookup with api.siteSettings in apiInitializer"
```

---

## Task 3 : Corriger controllers/news.js — services non injectés

**Files:**
- Modify: `assets/javascripts/discourse/controllers/news.js`

### Contexte

`DiscoveryListController` parent peut injecter `site` et `siteSettings` via héritage classique Ember, mais dans une classe ES6 explicite ce n'est pas garanti en Glimmer. Les déclarer explicitement avec `@service` est requis.

### Steps

- [ ] **Step 1 : Ajouter les injections de service**

Contenu complet du fichier après modification :

```javascript
import { service } from "@ember/service";
import DiscoveryListController from "discourse/controllers/discovery/list";

export default class NewsController extends DiscoveryListController {
  @service site;
  @service siteSettings;

  get showSidebar() {
    return this.showSidebarTopics && !this.site.mobileView;
  }

  get showSidebarTopics() {
    return (
      this.model?.sidebarTopics &&
      this.siteSettings.discourse_news_sidebar_topic_list
    );
  }

  get sidebarTopics() {
    return this.model?.sidebarTopics ?? [];
  }
}
```

Note : `this.sidebarTopics` et `this.showSidebarTopics` lisent maintenant depuis `this.model.sidebarTopics` (injecté via la route — voir Task 4). Plus de `controller.set()`.

- [ ] **Step 2 : Commit**

```bash
git add assets/javascripts/discourse/controllers/news.js
git commit -m "fix: add explicit @service injections to NewsController, read sidebarTopics from model"
```

---

## Task 4 : Corriger routes/news.js — sidebarTopics via modèle

**Files:**
- Modify: `assets/javascripts/discourse/routes/news.js`

### Contexte

`controller.set("sidebarTopics", ...)` est fragile sur un contrôleur Glimmer (l'état n'est pas réactif). La solution propre est de faire passer `sidebarTopics` dans l'objet modèle retourné par `model()`, ainsi le contrôleur y accède via `this.model.sidebarTopics`.

### Steps

- [ ] **Step 1 : Refactorer la route pour inclure sidebarTopics dans le modèle**

Contenu complet du fichier après modification :

```javascript
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import buildTopicRoute from "discourse/routes/build-topic-route";

export default class NewsRoute extends buildTopicRoute("news") {
  @service siteSettings;
  @service site;
  @service store;

  async #fetchSidebarTopics() {
    if (
      !this.siteSettings.discourse_news_sidebar_topic_list ||
      this.site.mobileView
    ) {
      return null;
    }

    const filter =
      this.siteSettings.discourse_news_sidebar_topic_list_filter || "latest";
    const list = await this.store.findFiltered("topicList", { filter });
    const limit =
      this.siteSettings.discourse_news_sidebar_topic_list_limit || 10;
    return list.topics.slice(0, limit);
  }

  async model(data, transition) {
    const sidebarTopics = await this.#fetchSidebarTopics();

    if (this.siteSettings.discourse_news_source === "rss") {
      const result = await ajax("/news").catch(popupAjaxError);
      return {
        filter: "",
        topics: result.map((t) => ({
          title: t.title,
          description: t.description,
          url: t.url,
          image_url: t.image_url,
          rss: true,
        })),
        sidebarTopics,
      };
    }

    const base = await super.model(data, transition);
    return Object.assign(base, { sidebarTopics });
  }

  setupController(controller, model) {
    super.setupController(controller, model);
  }
}
```

Note : `afterModel()` est supprimé — la logique est fusionnée dans `model()`. `setupController()` n'a plus besoin de faire `controller.set(...)`.

- [ ] **Step 2 : Commit**

```bash
git add assets/javascripts/discourse/routes/news.js
git commit -m "fix: pass sidebarTopics via route model instead of controller.set()"
```

---

## Task 5 : Convertir templates/news.hbs → templates/news.gjs

**Files:**
- Delete: `assets/javascripts/discourse/templates/news.hbs`
- Create: `assets/javascripts/discourse/templates/news.gjs`

### Contexte

`news.hbs` contient 5 problèmes critiques interdépendants :
- `{{topic-list ...}}` curly-brace invocation supprimée → `<List>` (import `discourse/components/topic-list/list`)
- `(action "changeSort")` / `(action "toggleBulkSelect")` supprimés → `{{fn this.changeSort}}`
- `{{{i18n ...}}}` triple-mustache supprimé → `{{htmlSafe (i18n ...)}}`
- `{{topic-link topic}}` → `<TopicLink @topic={{topic}} />`
- `{{format-date ...}}` → `{{formatDate ...}}`
- `model.hideCategory` / `model.topics` → `@model.hideCategory` / `@model.topics`
- `this.sidebarTopics` → `@model.sidebarTopics` (provient de la route — Task 4)

Le template de route Discourse reçoit `@model` comme argument nommé.

Les getters `showSidebar` et `showSidebarTopics` restent dans le contrôleur (Task 3) et sont accédés via `this.` dans le template.

### Steps

- [ ] **Step 1 : Supprimer l'ancien fichier .hbs**

```bash
rm /mnt/media1.intra/Dev/Dev/Andy/github/discourse-news/assets/javascripts/discourse/templates/news.hbs
```

- [ ] **Step 2 : Créer le nouveau fichier news.gjs**

Créer `assets/javascripts/discourse/templates/news.gjs` avec ce contenu exact :

```javascript
import { fn } from "@ember/helper";
import { htmlSafe } from "@ember/template";
import DiscoveryTopicsList from "discourse/components/discovery-topics-list";
import List from "discourse/components/topic-list/list";
import TopicLink from "discourse/components/topic-list/topic-link";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";

<template>
  <div class="topic-list-contents">
    <DiscoveryTopicsList
      @model={{@model}}
      @incomingCount={{@controller.topicTrackingState.incomingCount}}
      @bulkSelectHelper={{@bulkSelectHelper}}
    >
      {{#if @controller.hasTopics}}
        <List
          @top={{@controller.top}}
          @showTopicPostBadges={{@controller.showTopicPostBadges}}
          @showPosters={{true}}
          @canBulkSelect={{@controller.canBulkSelect}}
          @bulkSelectHelper={{@bulkSelectHelper}}
          @changeSort={{fn @controller.changeSort}}
          @hideCategory={{@model.hideCategory}}
          @order={{@controller.order}}
          @ascending={{@controller.ascending}}
          @expandGloballyPinned={{@controller.expandGloballyPinned}}
          @expandAllPinned={{@controller.expandAllPinned}}
          @category={{@controller.category}}
          @topics={{@model.topics}}
          @discoveryList={{true}}
          @listContext="discovery"
        />
      {{/if}}
    </DiscoveryTopicsList>
  </div>

  {{#if @controller.showSidebar}}
    <div class="sidebar">
      {{#if @controller.showSidebarTopics}}
        <div class="sidebar-title">
          {{i18n "news.sidebar_topics_title"}}
        </div>
        <ul>
          {{#each @model.sidebarTopics as |topic|}}
            <li>
              <div class="sidebar-topic-title">
                <TopicLink @topic={{topic}} />
              </div>
              <div class="sidebar-topic-meta">
                <span>{{formatDate topic.bumpedAt leaveAgo="true"}}</span>
                <span>{{i18n "changed_by" author=topic.creator.username}}</span>
                {{#if topic.category}}
                  <span>{{htmlSafe (i18n "in_category" basicCategoryLink=topic.basicCategoryLinkHtml)}}</span>
                {{/if}}
              </div>
            </li>
          {{/each}}
        </ul>
      {{/if}}
    </div>
  {{/if}}
</template>
```

**Note sur `@controller`** : Dans un template de route Discourse (`.gjs` placé dans `templates/`), le contrôleur est accessible via l'arg `@controller` (pattern Ember pour les route templates en Glimmer). Les propriétés comme `hasTopics`, `changeSort`, `canBulkSelect`, etc. viennent de `DiscoveryListController` (héritage du contrôleur — Task 3).

**Note sur `fn @controller.changeSort`** : Le `fn` helper crée un callback partiel depuis la méthode du contrôleur. Aucun argument partiel n'est nécessaire ici — `List` appellera le callback avec les arguments de tri.

- [ ] **Step 3 : Commit**

```bash
git add assets/javascripts/discourse/templates/news.gjs
git commit -m "feat: convert news.hbs to news.gjs — replace curly-syntax, triple-mustache, and action helpers with Glimmer equivalents"
```

---

## Task 6 : Corriger le connector topic-list-item — @topic → @outletArgs.topic

**Files:**
- Modify: `assets/javascripts/discourse/connectors/topic-list-item/news-topic-list-item.gjs`

### Contexte

Dans les outlets Glimmer modernes de Discourse, les arguments passés à l'outlet ne sont **pas** disponibles directement comme `@topic` — ils sont dans l'objet `@outletArgs`. Accéder à `@topic` directement retourne `undefined`.

Le `{{yield}}` dans le `{{else}}` est également problématique : l'outlet wrapper Glimmer gère automatiquement le rendu du contenu par défaut quand le composant connecteur ne rend rien. Il faut supprimer la branche `{{else}}{{yield}}{{/if}}` et ne rendre que quand on est sur la route news.

### Steps

- [ ] **Step 1 : Corriger le connector**

Contenu complet du fichier après modification :

```javascript
import Component from "@glimmer/component";
import { service } from "@ember/service";
import bodyClass from "discourse/helpers/body-class";
import NewsItem from "../../components/news-item";

export default class NewsTopicListItem extends Component {
  @service router;
  @service siteSettings;

  get isNewsRoute() {
    return this.router.currentRouteName === "news";
  }

  get showReplies() {
    return (
      this.siteSettings.discourse_news_source === "category" &&
      this.siteSettings.discourse_news_show_reply_count
    );
  }

  <template>
    {{#if this.isNewsRoute}}
      {{bodyClass "news"}}
      <NewsItem
        @topic={{@outletArgs.topic}}
        @showReplies={{this.showReplies}}
      />
    {{/if}}
  </template>
}
```

**Pourquoi supprimer `{{else}}{{yield}}`** : L'outlet `topic-list-item` est un outlet "wrapper" — quand le connecteur ne rend rien (pas sur la route news), l'outlet affiche automatiquement le contenu par défaut (le topic list item standard). Le `{{yield}}` explicite dans un connecteur Glimmer peut provoquer un double-rendu.

- [ ] **Step 2 : Commit**

```bash
git add assets/javascripts/discourse/connectors/topic-list-item/news-topic-list-item.gjs
git commit -m "fix: use @outletArgs.topic in Glimmer outlet connector, remove explicit yield"
```

---

## Vérification finale

- [ ] **Lancer RuboCop**

```bash
bundle exec rubocop plugins/discourse-news/plugin.rb
```

Résultat attendu : pas d'erreurs critiques (warnings éventuels sur le SQL inline sont acceptables).

- [ ] **Vérifier que le fichier .hbs est bien supprimé**

```bash
ls assets/javascripts/discourse/templates/
```

Résultat attendu : seul `news.gjs` présent, pas de `news.hbs`.

- [ ] **Vérifier la structure finale des fichiers JS**

```bash
find assets/javascripts -name "*.js" -o -name "*.gjs" | sort
```

Résultat attendu :
```
assets/javascripts/discourse/api-initializers/discourse-news.gjs
assets/javascripts/discourse/components/news-header-button.gjs
assets/javascripts/discourse/components/news-item-title.gjs
assets/javascripts/discourse/components/news-item.gjs
assets/javascripts/discourse/connectors/topic-list-item/news-topic-list-item.gjs
assets/javascripts/discourse/controllers/news.js
assets/javascripts/discourse/news-route-map.js
assets/javascripts/discourse/routes/news.js
assets/javascripts/discourse/templates/news.gjs
```

- [ ] **Vérifier qu'aucune référence ember-this-fallback ou MultiJson ne subsiste**

```bash
grep -r "ember-this-fallback\|MultiJson\|include_condition\|ArraySerializer\|api\.container\.lookup" assets/ plugin.rb
```

Résultat attendu : aucune ligne.
