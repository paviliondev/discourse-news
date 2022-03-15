import { withPluginApi } from 'discourse/lib/plugin-api';
import { default as discourseComputed, on, observes } from 'discourse-common/utils/decorators';
import { alias } from "@ember/object/computed";
import { findRawTemplate } from "discourse-common/lib/raw-templates";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import { emojiUnescape } from "discourse/lib/text";
import { notEmpty } from "@ember/object/computed";
import { h } from 'virtual-dom';
import { inject as service } from "@ember/service";
import { scheduleOnce } from "@ember/runloop";
import showModal from "discourse/lib/show-modal";

export default {
  name: 'news-edits',
  initialize(container){
    const siteSettings = container.lookup('site-settings:main');

    if (!siteSettings.discourse_news_enabled) return;

    withPluginApi('0.8.12', (api) => {
      api.modifyClass('controller:discovery', {
        router: service(),
        
        @on('init')
        @observes('router.currentRouteName')
        toggleClass() {
          const route = this.get('router.currentRouteName');
          scheduleOnce('afterRender', () => {
            $('#list-area').toggleClass('news', route === 'news');
          });
        }
      });

      api.modifyClass('controller:discovery/topics', {
        actions: {
          refresh() {
            const route = this.get('router.currentRouteName');
            if (route === 'news') return;
            return this._super();
          }
        }
      });

      api.modifyClass('component:topic-list', {
        router: service(),
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
            const newsCategoryId = this.siteSettings.discourse_news_category;
            const newsCategory = this.site.get("categoriesList").find(c => c.id === newsCategoryId);
            this.set('category', newsCategory);
            $('body').addClass('news');
          } else {
            $('body').removeClass('news');
          }
        }
      });

      api.modifyClass('component:topic-list-item', {
        newsRoute: alias('parentView.newsRoute'),
        
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
          const siteSettings = this.siteSettings;
          const topicSource = siteSettings.discourse_news_source === 'category';
          const showReplies = siteSettings.discourse_news_show_reply_count;
          return newsRoute && topicSource && showReplies;
        },

        click(e) {
          let t = e.target;
          if (!t) {
            return this._super(e);
          }
          if (t.closest(".share")) {
            const controller = showModal("share-topic", {
              model: this.topic.category,
            });
            controller.set('topic', this.topic);
            return true;
          }
          return this._super(e);
        },
      });

      api.modifyClass('component:site-header', {
        router: service(),
        currentRoute: alias('router.currentRouteName'),

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
        @discourseComputed("news_body")
        escapedNewsBody(newsBody) {
          return emojiUnescape(newsBody);
        },
        
        @discourseComputed("category")
        basicCategoryLinkHtml(category) {
          return `<a class="basic-category-link"
                     href="${category.url}"
                     title="${category.name}">
                    ${category.name}
                  </a>`;
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
