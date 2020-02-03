import { withPluginApi } from 'discourse/lib/plugin-api';
import { default as discourseComputed, on, observes } from 'discourse-common/utils/decorators';
import { alias } from "@ember/object/computed";
import { findRawTemplate } from "discourse/lib/raw-templates";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import { emojiUnescape } from "discourse/lib/text";
import { notEmpty } from "@ember/object/computed";
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
          Ember.run.scheduleOnce('afterRender', () => {
            $('#list-area').toggleClass('news', route === 'news');
          });
        }
      });

      api.modifyClass('controller:discovery/topics', {
        actions: {
          refresh() {
            const route = this.get('discovery.application.currentRouteName');
            if (route === 'news') return;
            return this._super();
          }
        }
      });

      api.modifyClass('component:topic-list', {
        router: Ember.inject.service('-routing'),
        currentRoute: alias('router.currentRouteName'),
        
        @discourseComputed('currentRoute')
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
            $('body').addClass('news');
          } else {
            $('body').removeClass('news');
          }
        }
      });

      api.modifyClass('component:topic-list-item', {
        newsRoute: Ember.computed.alias('parentView.newsRoute'),
        
        @observes("topic.pinned")
        renderTopicListItem() {
          if (this.get('newsRoute')) {
            const template = findRawTemplate("list/news-item");
            if (template) {
              this.set("topicListItemContents", template(this).htmlSafe());
            }
          } else {
            return this._super();
          }
        },

        @discourseComputed('newsRoute')
        showReplies(newsRoute) {
          const siteSettings = Discourse.SiteSettings;
          const topicSource = siteSettings.discourse_news_source === 'category';
          const showReplies = siteSettings.discourse_news_show_reply_count;
          return newsRoute && topicSource && showReplies;
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
      
      api.modifyClass('model:topic', {                
        @discourseComputed("news_excerpt")
        escapedNewsExcerpt(newsExcerpt) {
          return emojiUnescape(newsExcerpt);
        }
      });
      
      api.modifyClass('controller:discovery/topics', {
        @discourseComputed('showSidebarTopics')
        showSidebar(showSidebarTopics) {
          return showSidebarTopics && !this.site.mobileView;
        },
        
        @discourseComputed('sidebarTopics')
        showSidebarTopics(sidebarTopics) {
          return sidebarTopics && siteSettings.discourse_news_sidebar_topic_list;
        }
      })
    });
  }
};
