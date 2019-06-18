import { withPluginApi } from 'discourse/lib/plugin-api';
import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import { findRawTemplate } from "discourse/lib/raw-templates";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import { h } from 'virtual-dom';

export default {
  name: 'news-edits',
  initialize(container){
    const siteSettings = container.lookup('site-settings:main');

    if (!siteSettings.discourse_news_enabled) return;

    withPluginApi('0.8.12', (api) => {
      api.modifyClass('controller:discovery', {
        @on('init')
        @observes('application.currentRouteName')
        toggleClass() {
          const route = this.get('application.currentRouteName');
          const isNewsRoute = route === 'news';
          Ember.run.scheduleOnce('afterRender', () => {
            $('#list-area').toggleClass('news', isNewsRoute);
          });
        }
      });

      api.modifyClass('controller:discovery/topics', {
        actions: {
          refresh() {
            const discovery = this.get('discovery');
            const route = discovery.get('application.currentRouteName');
            const isNewsRoute = route === 'news';
            if (isNewsRoute) {
              return;
            } else {
              return this._super();
            }
          }
        }
      });

      api.modifyClass('component:topic-list', {
        @computed('newsRoute')
        routeEnabled(newsRoute) {
          if (newsRoute) {
            return ['topic_list_social'];
          } else {
            return false;
          }
        },

        @computed('currentRoute')
        newsRoute(currentRoute) {
          return currentRoute === 'news';
        },

        @on('didInsertElement')
        @observes('newsRoute')
        setupNews() {
          const newsRoute = this.get('newsRoute');
          if (newsRoute) {
            const newsCategoryId = Discourse.SiteSettings.discourse_news_category;
            const newsCategory = this.site.get("categoriesList").find(c => c.id === newsCategoryId);
            this.set('category', newsCategory);
          }
        }
      });

      api.modifyClass('component:topic-list-item', {
        newsRoute: Ember.computed.alias('parentView.newsRoute'),

        buildBuffer(buffer) {
          if (this.get('newsRoute')) {
            const template = findRawTemplate("list/news-item");
            if (template) {
              buffer.push(template(this));
            }
          } else {
            return this._super(buffer);
          }
        },

        @on('init')
        setupNews() {
          if (this.get('newsRoute')) {
            this.setProperties({
              thumbnailWidth: 700,
              thumbnailHeight: 400
            });

            if (this.get('showNewsMeta')) {
              Ember.run.scheduleOnce('afterRender', () => {
                this._setupActions();
              });
            }
          }
        },

        @computed('newsRoute')
        showNewsMeta(newsRoute) {
          const siteSettings = Discourse.SiteSettings;
          const source = siteSettings.discourse_news_source;
          const topicSource = source === 'category';
          const metaEnabled = siteSettings.discourse_news_meta;
          return newsRoute && topicSource && metaEnabled;
        }
      });

      api.modifyClass('component:share-popup', {
        @on('didInsertElement')
        getTopicId() {
          const newsShare = this.get('newsShare');
          if (newsShare) {
            const topicMap = this.get('topics').reduce((map, t) => {
              map[t.id] = t;
              return map;
            }, {});

            $("html").on(
            "click.discourse-share-link-topic",
            "button[data-share-url]", e => {
              if (wantsNewWindow(e)) {
                return true;
              }
              const $currentTarget = $(e.currentTarget);
              const topicId = $currentTarget.closest("tr").data("topic-id");
              this.set('topic', topicMap[topicId]);
            });
          }
        },

        @on('willDestroyElement')
        teardownGetTopicId() {
          $("html").off("click.discourse-share-link-topic");
        }
      });

      api.modifyClass('component:site-header', {
        router: Ember.inject.service('-routing'),
        currentRoute: Ember.computed.alias('router.router.currentRouteName'),

        @observes('currentRoute')
        rerenderWhenRouteChanges() {
          this.queueRerender();
        },

        buildArgs() {
          return $.extend(this._super(), {
            currentRoute: this.get('currentRoute')
          });
        }
      });

      api.reopenWidget('header-buttons', {
        html(attrs) {
          let buttons = this._super(attrs) || [];
          let className = 'header-nav-link news';

          if (attrs.currentRoute === 'news') {
            className += ' active';
          }

          let linkAttrs = {
            href: '/news',
            label: 'filters.news.title',
            className
          };

          const icon = siteSettings.discourse_news_icon;
          if (icon && icon.indexOf('/') > -1) {
            linkAttrs['contents'] = () => {
              return [
                h('img', { attributes: { src: icon }}),
                h('span', I18n.t('filters.news.title'))
              ];
            };
          } else if (icon) {
            linkAttrs['icon'] = icon;
          }

          buttons.unshift(this.attach('link', linkAttrs));

          return buttons;
        }
      });
    });
  }
};
