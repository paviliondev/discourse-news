import buildTopicRoute from "discourse/routes/build-topic-route";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";

const source = Discourse.SiteSettings.discourse_news_source;

export default buildTopicRoute('news', {
  model(data, transition) {
    if (source === 'rss') {
      return ajax("/news/rss").catch(popupAjaxError);;
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
