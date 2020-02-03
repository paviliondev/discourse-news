import buildTopicRoute from "discourse/routes/build-topic-route";
import { popupAjaxError } from 'discourse/lib/ajax-error';
import { ajax } from 'discourse/lib/ajax';

const settings = Discourse.SiteSettings;

export default buildTopicRoute('news', {
  model(data, transition) {
    if (settings.discourse_news_source === 'rss') {
      return ajax("/news").then((result) => {
        return Ember.Object.create({
          filter: '',
          topics: result.map(t => {
            return Ember.Object.create({
              title: t.title,
              description: t.description,
              url: t.url,
              image_url: t.image_url,
              rss: true
            });
          })
        });
      }).catch(popupAjaxError);
    } else {
      return this._super(data, transition);
    }
  },
      
  afterModel(model) {
    if (settings.discourse_news_sidebar_topic_list && !this.site.mobileView) {
      const filter = settings.discourse_news_sidebar_topic_list_filter || 'latest';
      return this.store.findFiltered("topicList", { filter })
        .then(list => {
          const limit = settings.discourse_news_sidebar_topic_list_limit || 10;
          this.set('sidebarTopics', list.topics.slice(0, limit));
        });
    } else {
      return true;
    }
  },
  
  renderTemplate() {
    this.render("news", {
      controller: "discovery/topics",
      outlet: "list-container"
    });
  },
  
  setupController(controller, model) {
    this._super(controller, model);
    let extraOpts = {};
    if (this.sidebarTopics) extraOpts['sidebarTopics'] = this.sidebarTopics;
    this.controllerFor("discovery/topics").setProperties(extraOpts);
  },
});
