import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import buildTopicRoute from "discourse/routes/build-topic-route";

export default class NewsRoute extends buildTopicRoute("news") {
  @service siteSettings;
  @service site;
  @service store;

  model(data, transition) {
    if (this.siteSettings.discourse_news_source === "rss") {
      return ajax("/news")
        .then((result) => ({
          filter: "",
          topics: result.map((t) => ({
            title: t.title,
            description: t.description,
            url: t.url,
            image_url: t.image_url,
            rss: true,
          })),
        }))
        .catch(popupAjaxError);
    } else {
      return super.model(data, transition);
    }
  }

  afterModel() {
    if (
      this.siteSettings.discourse_news_sidebar_topic_list &&
      !this.site.mobileView
    ) {
      const filter =
        this.siteSettings.discourse_news_sidebar_topic_list_filter || "latest";
      return this.store.findFiltered("topicList", { filter }).then((list) => {
        const limit =
          this.siteSettings.discourse_news_sidebar_topic_list_limit || 10;
        this.sidebarTopics = list.topics.slice(0, limit);
      });
    }
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    if (this.sidebarTopics) {
      controller.set("sidebarTopics", this.sidebarTopics);
    }
  }
}
