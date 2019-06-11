import buildTopicRoute from "discourse/routes/build-topic-route";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";

export default buildTopicRoute('news', {
  model(data, transition) {
    const source = Discourse.SiteSettings.discourse_news_source;
    if (source === 'rss') {
      return ajax("/news/rss").then((result) => {
        return Ember.Object.create({
          filter: '',
          topics: result.list.map(t => {
            return Ember.Object.create({
              title: t.title,
              description: t.description,
              url: t.url,
              image_url: t.image_url,
              rss: true
            });
          })
        });
      }).catch(popupAjaxError);;
    } else {
      return this._super(data, transition);
    }
  },

  renderTemplate() {
    this.render("discovery/topics", {
      controller: "discovery/topics",
      outlet: "list-container"
    });
  }
});
